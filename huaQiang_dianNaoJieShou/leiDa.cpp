#include <iostream>
#include <winsock2.h>
#include <vector>
#include <string>
#include <algorithm>

#pragma comment(lib, "ws2_32.lib")  // Winsock 库

#define SERVER_IP "192.168.37.33"  // 服务端IP地址
#define SERVER_PORT 8082           // 服务端端口
#define BUFFER_SIZE 1024           // 数据缓冲区大小
#define EXPECTED_DATA_SIZE 10022   // 期望接收到的数据大小（包括包头、包长度等）

// 用于计算距离，单位为毫米，直接取int因为结果不用很精确
int Distance(char byte) {
    int decimalNum = static_cast<unsigned char>(byte);  // 直接将字符转换为无符号整型
    return (decimalNum / 5.1) * (decimalNum / 5.1);  // 计算距离
}


// 避障函数，判断是否有障碍, 如果分区内有超过百分之20的小于阈值的点那么就会报警
bool AvoidObstacle(const std::vector<std::vector<int>>& distances, const int threshold[], int horizontal_parts, int vertical_parts) {
    const int rows = 100, cols = 100;
    const int h_part_size = cols / horizontal_parts, v_part_size = rows / vertical_parts;

    for (int v = 0; v < vertical_parts; ++v) {
        for (int h = 0; h < horizontal_parts; ++h) {
            std::vector<int> points;

            // 采样分区数据（可优化为间隔采样降低计算量）
            for (int i = v * v_part_size; i < (v + 1) * v_part_size; ++i)
                for (int j = h * h_part_size; j < (h + 1) * h_part_size; ++j) {
                    int dist = distances[i][j];
                    if (dist != 0) {  // 过滤掉值为0的数据
                        points.push_back(dist);
                    }
                }

            if (points.empty()) continue;  // 如果有效数据为空，跳过该分区

            // 排序数据
            std::sort(points.begin(), points.end());

            // 计算低百分之二十的数据
            int num_of_points = points.size();
            int low_percentile_count = num_of_points / 5;  // 20% 的数据

            // 提取低百分之二十的数据
            std::vector<int> low_percentile_points(points.begin(), points.begin() + low_percentile_count);

            // 计算这些低百分之二十数据的平均值
            if (low_percentile_points.empty()) {
                std::cout << "No valid data in the low 20% range for sector [" << v << "," << h << "]" << std::endl;
                continue; // 如果没有数据，跳过此分区
            }

            double sum = 0;
            for (int val : low_percentile_points) {
                sum += val;
            }
            double avg = sum / low_percentile_points.size();

            // 获取当前分区的阈值
            int index = v * horizontal_parts + h;
            int current_threshold = threshold[index];  // 选择当前分区对应的阈值

            // 打印计算的平均值
            std::cout << "Low 20% average in sector [" << v << "," << h << "]: " << avg << "mm, Threshold: " << current_threshold << "mm" << std::endl;

            // 如果低百分之二十的平均值小于阈值，触发报警
            if (avg < current_threshold) {
                std::cout << "ALERT: Obstacle in sector [" << v << "," << h
                          << "] - Low 20% avg=" << avg << "mm\n";
                return true;
            }
        }
    }
    return false;
}

int main() {
    WSADATA wsaData;
    SOCKET client_socket;
    struct sockaddr_in server_addr;
    int threshold[12] = {700, 700, 700, 700, 700, 700, 700, 700, 1600, 1600, 1600, 1600};  // 每个分区的阈值

    // 初始化 Winsock
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        std::cerr << "WSAStartup failed. Error Code: " << WSAGetLastError() << std::endl;
        return 1;
    }

    // 创建套接字
    if ((client_socket = socket(AF_INET, SOCK_STREAM, 0)) == INVALID_SOCKET) {
        std::cerr << "Socket creation failed. Error Code: " << WSAGetLastError() << std::endl;
        WSACleanup();
        return 1;
    }

    // 配置服务端地址
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(SERVER_PORT);
    server_addr.sin_addr.s_addr = inet_addr(SERVER_IP);

    // 连接到服务端
    if (connect(client_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) == SOCKET_ERROR) {
        std::cerr << "Connection failed. Error Code: " << WSAGetLastError() << std::endl;
        closesocket(client_socket);
        WSACleanup();
        return 1;
    }

    std::cout << "Connected to server at " << SERVER_IP << ":" << SERVER_PORT << std::endl;

    char buffer[BUFFER_SIZE];
    std::string received_data;

    // 定义一个 100x100 的二维向量distances，用来存储数据
    const int rows = 100;
    const int cols = 100;
    std::vector<std::vector<int>> distances(rows, std::vector<int>(cols, 0));

    // 避障阈值（单位：毫米）
    // 这里每个分区有不同的阈值，可以根据实际情况调整
    const int horizontal_parts = 4; // 水平分区数
    const int vertical_parts = 3;   // 垂直分区数

    while (true) {
        // 清空接收缓冲区
        received_data.clear();

        // 接收数据直到接收到足够的数据
        while (received_data.size() < EXPECTED_DATA_SIZE) {
            int bytes_received = recv(client_socket, buffer, BUFFER_SIZE, 0);
            if (bytes_received > 0) {
                received_data.append(buffer, bytes_received);
            } else if (bytes_received == 0) {
                std::cout << "Server disconnected" << std::endl;
                break;
            } else {
                std::cerr << "Receive failed. Error Code: " << WSAGetLastError() << std::endl;
                break;
            }
        }

        // 如果接收到的数据量已经足够
        if (received_data.size() >= EXPECTED_DATA_SIZE) {
            // 获取包长度（2字节）
            unsigned short package_length = (static_cast<unsigned char>(received_data[2]) << 8) |
                                            static_cast<unsigned char>(received_data[3]);

            // 图像帧数据开始位置：16字节后
            size_t image_frame_start = 4 + 16;  // 包头（2字节）+ 包长度（2字节）+ 其他内容（16字节）

            // 提取图像帧数据
            std::string image_frame_data = received_data.substr(image_frame_start, package_length - 16 - 3); // 减去包头（2字节）和包尾（1字节）

            // 计算并存储图像帧的数据到二维向量
            size_t index = 0;
            for (int i = 0; i < rows; ++i) {
                for (int j = 0; j < cols; ++j) {
                    if (index < image_frame_data.size()) {
                        // 计算每个字节的距离并存入二维向量
                        distances[i][j] = Distance(image_frame_data[index]);
                        ++index;
                    }
                }
            }

            // 进行避障判断
            if (AvoidObstacle(distances, threshold, horizontal_parts, vertical_parts)) {
                std::cout << "Obstacle detected! Taking evasive action..." << std::endl;
                // 在这里添加避障策略，例如停止、转向等
            } else {
                std::cout << "No obstacle detected. Continuing..." << std::endl;
            }

            // 清空缓存，准备接收新的数据
            received_data.clear();
        } else {
            std::cerr << "Received data size less than expected, something went wrong!" << std::endl;
            break;
        }
    }

    // 关闭套接字
    closesocket(client_socket);

    // 清理 Winsock
    WSACleanup();

    return 0;
}
