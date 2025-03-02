import 'package:dart_openai/dart_openai.dart';

class OpenAIService {
  OpenAIService() {
    OpenAI.apiKey = 'sk-9608d82aba824991a36c629aef67cc87';
    OpenAI.baseUrl = 'https://dashscope.aliyuncs.com/compatible-mode/v1';
  }

  Future<String> analyzeImage(String base64Image) async {
    try {
      final chatCompletion = await OpenAI.instance.chat.create(
        model: "qwen-vl-plus", // 使用通义千问视觉模型
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
                "data:image/jpeg;base64,$base64Image",
              ),
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                "我是一个视障人员，请为我描述这张图片的内容",
              ),
            ],
          ),
        ],
      );

      // 获取模型返回的消息
      final message = chatCompletion.choices.first.message;

      // 直接访问原始内容，无需做类型转换
      if (message.content == null) {
        return "未获取到图像分析结果";
      }

      // 安全地返回内容，确保是字符串
      return message.content.toString();
    } catch (e) {
      print("图片分析失败: $e");
      return "图片分析失败: $e";
    }
  }
}
