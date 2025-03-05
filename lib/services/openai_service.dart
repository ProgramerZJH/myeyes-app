import 'package:openai_dart/openai_dart.dart';

class OpenAIService {
  final OpenAIClient _client;

  OpenAIService()
      : _client = OpenAIClient(
          apiKey: 'sk-9608d82aba824991a36c629aef67cc87',
          baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
        );

  Future<String> analyzeImage(String base64Image) async {
    try {
      final res = await _client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: const ChatCompletionModel.modelId("qwen-vl-plus"),
          messages: [
            const ChatCompletionMessage.system(
              content: "你是一个专业的视觉辅助助手，需要为视障人士详细描述图片内容",
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.parts([
                ChatCompletionMessageContentPart.text(
                  text: "请用中文详细描述这张图片的内容，注意包含以下要素："
                      "1. 主要物体及其位置关系\n"
                      "2. 颜色和形状信息\n"
                      "3. 文字内容（如果有）\n"
                      "4. 可能存在的潜在危险",
                ),
                ChatCompletionMessageContentPart.image(
                  imageUrl: ChatCompletionMessageImageUrl(
                    url: "data:image/jpeg;base64,$base64Image",
                  ),
                ),
              ]),
            ),
          ],
          temperature: 0.2,
          maxTokens: 1000,
        ),
      );
      return res.choices.first.message.content ?? "未获取到描述内容";
    } catch (e) {
      print("图片分析失败: $e");
      return "图片分析失败，请稍后再试";
    }
  }
}
