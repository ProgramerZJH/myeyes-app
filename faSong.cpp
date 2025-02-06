#include <WINSOCK2.H>
#include <ws2tcpip.h>
#include <opencv2/opencv.hpp>
#include <iostream>
#include <vector>
#include <cstddef>
#include <fstream>

#pragma comment(lib, "ws2_32.lib")

#define PORT 8080
#define BUFFER_SIZE 1024
typedef unsigned char uchar;

void handle_error(const std::string &message, int socket = -1) {
    std::cerr << message << " Error code: " << WSAGetLastError() << std::endl;
    if (socket != -1) {
        closesocket(socket);
    }
    WSACleanup();
    exit(-1);
}

bool receive_data(int sock, uint32_t &image_size, std::vector<uchar> &buffer) {
    // 接收图像大小
    if (recv(sock, reinterpret_cast<char *>(&image_size), sizeof(image_size), 0) <= 0) {
        std::cerr << "Failed to receive image size." << std::endl;
        return false;
    }

    std::cout << "Receiving image of size " << image_size << " bytes" << std::endl;
    buffer.resize(image_size);

    // 分块接收图像数据
    size_t received_bytes = 0;
    while (received_bytes < image_size) {
        ssize_t bytes = recv(sock, reinterpret_cast<char *>(buffer.data()) + received_bytes, image_size - received_bytes, 0);
        if (bytes <= 0) {
            std::cerr << "Failed to receive image data." << std::endl;
            return false;
        }
        received_bytes += bytes;
    }

    return received_bytes == image_size;
}

int main() {
    WSADATA wsaData;
    int result = WSAStartup(MAKEWORD(2, 2), &wsaData);
    if (result != 0) {
        std::cerr << "WSAStartup failed: " << result << std::endl;
        return -1;
    }

    int sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sock == INVALID_SOCKET) {
        handle_error("Socket creation failed");
    }

    sockaddr_in serv_addr = {};
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(PORT);

    if (inet_pton(AF_INET, "192.168.185.33", &serv_addr.sin_addr) <= 0) {
        handle_error("Connection failed", sock);
    }

    if (connect(sock, reinterpret_cast<struct sockaddr*>(&serv_addr), sizeof(serv_addr)) < 0) {
        handle_error("Connection failed", sock);
    }

    std::cout << "Connected to server!" << std::endl;

    // OpenCV窗口
    cv::namedWindow("Received Image", cv::WINDOW_AUTOSIZE);

    // 在发送循环前添加帧同步机制
    uint32_t frame_counter = 0;  // 添加帧计数器

    while (true) {
        uint32_t image_size = 0;
        std::vector<uchar> buffer;

        // 重新尝试接收图像数据，直到成功
        while (!receive_data(sock, image_size, buffer)) {
            std::cerr << "Error receiving image data. Retrying..." << std::endl;
        }

        // 将接收到的字节数据解码为图像
        cv::Mat img = cv::imdecode(buffer, cv::IMREAD_COLOR);
        if (img.empty()) {
            std::cerr << "Failed to decode the image." << std::endl;
            continue;
        }

        // 在发送图像前进行JPEG编码
        std::vector<uchar> buffer_to_send;
        std::vector<int> params;
        params.push_back(cv::IMWRITE_JPEG_QUALITY);
        params.push_back(95); // 95% quality JPEG
        cv::imencode(".jpg", img, buffer_to_send, params);

        // 在发送前添加帧头信息
        struct FrameHeader {
            uint32_t frame_number;
            uint32_t data_size;
            uint32_t checksum;
        } header;

        header.frame_number = frame_counter++;
        header.data_size = buffer_to_send.size();
        header.checksum = header.frame_number ^ header.data_size;

        // 先发送帧头
        if (send(sock, reinterpret_cast<char*>(&header), 12, 0) <= 0) {
            std::cerr << "Failed to send frame header." << std::endl;
            continue;
        }

        // 再发送图像数据（分块发送）
        size_t sent_bytes = 0;
        while (sent_bytes < buffer_to_send.size()) {
            size_t chunk_size = std::min(buffer_to_send.size() - sent_bytes, (size_t)4096);
            ssize_t bytes = send(sock, reinterpret_cast<char*>(buffer_to_send.data()) + sent_bytes, chunk_size, 0);
            if (bytes <= 0) {
                std::cerr << "Failed to send image chunk." << std::endl;
                break;
            }
            sent_bytes += bytes;
        }

        // 显示图像
        cv::imshow("Received Image", img);

        // 按 'q' 键退出循环
        if (cv::waitKey(1) == 'q') {
            break;
        }
    }

    // 关闭套接字和清理
    closesocket(sock);
    WSACleanup();
    return 0;
}
