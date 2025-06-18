import 'dart:convert';
import 'dart:math';

class Character {
  final String riizeUserId;
  final String riizeUserName;
  final String riizeNickName;
  final String riizeUserIcon;
  final String riizeIntroduction;
  final String riizeSayHi;
  final String riizeShowVideo;
  final List<String> riizeShowVideoArray;
  final String riizeShowPhoto;
  final List<String> riizeShowPhotoArray;
  final String riizeShowMotto;
  final int riizeFansCount; // 粉丝数量字段
  bool isLiked; // 是否点赞
  int likeCount; // 点赞数

  Character({
    required this.riizeUserId,
    required this.riizeUserName,
    required this.riizeNickName,
    required this.riizeUserIcon,
    required this.riizeIntroduction,
    required this.riizeSayHi,
    required this.riizeShowVideo,
    required this.riizeShowVideoArray,
    required this.riizeShowPhoto,
    required this.riizeShowPhotoArray,
    required this.riizeShowMotto,
    required this.riizeFansCount,
    this.isLiked = false,
    this.likeCount = 0,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      riizeUserId: json['riizeUserId'],
      riizeUserName: json['riizeUserName'],
      riizeNickName: json['riizeNickName'],
      riizeUserIcon: json['riizeUserIcon'],
      riizeIntroduction: json['riizeIntroduction'],
      riizeSayHi: json['riizeSayHi'],
      riizeShowVideo: json['riizeShowVideo'],
      riizeShowVideoArray: List<String>.from(json['riizeShowVideoArray']),
      riizeShowPhoto: json['riizeShowPhoto'],
      riizeShowPhotoArray: List<String>.from(json['riizeShowPhotoArray']),
      riizeShowMotto: json['riizeShowMotto'],
      riizeFansCount: json['riizeFansCount'],
      isLiked: json['isLiked'] ?? false,
      likeCount: json['likeCount'] ?? Random().nextInt(4) + 1, // 随机 1-4 个点赞
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riizeUserId': riizeUserId,
      'riizeUserName': riizeUserName,
      'riizeNickName': riizeNickName,
      'riizeUserIcon': riizeUserIcon,
      'riizeIntroduction': riizeIntroduction,
      'riizeSayHi': riizeSayHi,
      'riizeShowVideo': riizeShowVideo,
      'riizeShowVideoArray': riizeShowVideoArray,
      'riizeShowPhoto': riizeShowPhoto,
      'riizeShowPhotoArray': riizeShowPhotoArray,
      'riizeShowMotto': riizeShowMotto,
      'riizeFansCount': riizeFansCount,
      'isLiked': isLiked,
      'likeCount': likeCount,
    };
  }
}

class CharacterData {
  static final Map<String, Character> characters = {
    "1": Character(
      riizeUserId: "1",
      riizeUserName: "Sophia Chen (ENFJ)",
      riizeNickName: "SophiaStyle",
      riizeUserIcon: "lib/assets/figure/1/p/1_p_2025_06_13_1.png",
      riizeIntroduction:
          "As an ENFJ, Sophia loves connecting with people through fashion. Her wardrobe reflects her warm personality - colorful, inviting, and thoughtfully put together. She believes clothes can bridge cultural gaps and create meaningful conversations.",
      riizeSayHi:
          "Hey there! I was just reorganizing my closet by color palette! Fashion is such a beautiful way to express yourself, don't you think? I'd love to hear about your style journey!",
      riizeShowVideo: "lib/assets/figure/1/v/1_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/1/v/1_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/1/p/1_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/1/p/1_p_2025_06_13_1.png",
        "lib/assets/figure/1/p/1_p_2025_06_13_2.png",
        "lib/assets/figure/1/p/1_p_2025_06_13_3.png"
      ],
      riizeShowMotto: "Style speaks when words can't.",
      riizeFansCount: 12,
    ),
    "2": Character(
      riizeUserId: "2",
      riizeUserName: "Emma Watson (INFP)",
      riizeNickName: "DreamyStyler",
      riizeUserIcon: "lib/assets/figure/2/p/2_p_2025_06_13_1.png",
      riizeIntroduction:
          "Emma, an INFP dreamer, sees fashion as poetry in motion. Her style is eclectic and deeply personal, often mixing vintage finds with modern pieces. She believes clothing should tell stories and evoke emotions rather than follow trends.",
      riizeSayHi:
          "Oh, hello! I was just sketching some outfit ideas inspired by this book I'm reading. Do you ever find inspiration for your style in unexpected places? I'd love to hear about it!",
      riizeShowVideo: "lib/assets/figure/2/v/2_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/2/v/2_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/2/p/2_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/2/p/2_p_2025_06_13_1.png",
        "lib/assets/figure/2/p/2_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Wear your imagination.",
      riizeFansCount: 10,
    ),
    "3": Character(
      riizeUserId: "3",
      riizeUserName: "Olivia Zhang (ENTJ)",
      riizeNickName: "OliviaLeads",
      riizeUserIcon: "lib/assets/figure/3/p/3_p_2025_06_13_1.png",
      riizeIntroduction:
          "ENTJ Olivia approaches fashion with strategic precision. Her wardrobe consists of powerful statement pieces that command attention. She believes in investing in quality over quantity and uses style as a tool to communicate confidence and authority.",
      riizeSayHi:
          "Great to connect! I just finished curating my capsule wardrobe for the season. Efficiency and impact are everything in fashion. What's your approach to building your wardrobe?",
      riizeShowVideo: "lib/assets/figure/3/v/3_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/3/v/3_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/3/p/3_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/3/p/3_p_2025_06_13_1.png",
        "lib/assets/figure/3/p/3_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Dress for the position you want.",
      riizeFansCount: 9,
    ),
    "4": Character(
      riizeUserId: "4",
      riizeUserName: "Mia Johnson (ISFP)",
      riizeNickName: "MiaAesthetic",
      riizeUserIcon: "lib/assets/figure/4/p/4_p_2025_06_13_1.png",
      riizeIntroduction:
          "As an ISFP, Mia has an innate sense of aesthetics. Her style is fluid and experimental, changing with her moods and inspirations. She sees fashion as an art form and her body as the canvas, creating visual harmony through colors and textures.",
      riizeSayHi:
          "Hi there! I just dyed some fabric for a new project. There's something magical about creating something unique, isn't there? What inspires your personal style these days?",
      riizeShowVideo: "lib/assets/figure/4/v/4_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/4/v/4_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/4/p/4_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/4/p/4_p_2025_06_13_1.png",
        "lib/assets/figure/4/p/4_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Beauty is in the details.",
      riizeFansCount: 11,
    ),
    "5": Character(
      riizeUserId: "5",
      riizeUserName: "Isabella Martinez (ISTJ)",
      riizeNickName: "ClassicBella",
      riizeUserIcon: "lib/assets/figure/5/p/5_p_2025_06_13_1.png",
      riizeIntroduction:
          "ISTJ Isabella values tradition and quality in fashion. Her meticulously organized wardrobe features timeless pieces that never go out of style. She researches extensively before purchasing and can tell you the history behind every fashion staple.",
      riizeSayHi:
          "Hello. I was just cataloging my collection of vintage scarves by decade. I find that understanding fashion history helps create more thoughtful outfits. Do you have any favorite classic pieces?",
      riizeShowVideo: "lib/assets/figure/5/v/5_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/5/v/5_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/5/p/5_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/5/p/5_p_2025_06_13_1.png",
        "lib/assets/figure/5/p/5_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Quality over quantity, always.",
      riizeFansCount: 7,
    ),
    "6": Character(
      riizeUserId: "6",
      riizeUserName: "Ava Williams (ENFP)",
      riizeNickName: "AvaAdventure",
      riizeUserIcon: "lib/assets/figure/6/p/6_p_2025_06_13_1.png",
      riizeIntroduction:
          "Ava, an enthusiastic ENFP, sees fashion as an adventure. Her wardrobe is a vibrant mix of patterns, textures, and cultural influences from her travels. She dresses according to her intuition and loves surprising others with unexpected combinations.",
      riizeSayHi:
          "Hiiii! OMG I just found the most AMAZING vintage shop yesterday and bought three completely different outfits! What's the most spontaneous fashion purchase you've ever made?",
      riizeShowVideo: "lib/assets/figure/6/v/6_v_2025_06_13_1.mp4",
      riizeShowVideoArray: [
        "lib/assets/figure/6/v/6_v_2025_06_13_1.mp4",
        "lib/assets/figure/6/v/6_v_2025_06_13_2.mp4"
      ],
      riizeShowPhoto: "lib/assets/figure/6/p/6_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/6/p/6_p_2025_06_13_1.png",
        "lib/assets/figure/6/p/6_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Life's too short for boring clothes.",
      riizeFansCount: 13,
    ),
    "7": Character(
      riizeUserId: "7",
      riizeUserName: "Charlotte Kim (INTJ)",
      riizeNickName: "StrategicChic",
      riizeUserIcon: "lib/assets/figure/7/p/7_p_2025_06_13_1.png",
      riizeIntroduction:
          "INTJ Charlotte approaches fashion with analytical precision. Her minimalist wardrobe is carefully curated for maximum versatility and efficiency. She sees personal style as a system to be optimized rather than a realm for emotional expression.",
      riizeSayHi:
          "Hello. I've been analyzing the cost-per-wear of my wardrobe items this season. Have you considered how strategic planning could improve your style efficiency while reducing environmental impact?",
      riizeShowVideo: "lib/assets/figure/7/v/7_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/7/v/7_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/7/p/7_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/7/p/7_p_2025_06_13_1.png",
        "lib/assets/figure/7/p/7_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Systematic style, deliberate choices.",
      riizeFansCount: 6,
    ),
    "8": Character(
      riizeUserId: "8",
      riizeUserName: "Zoe Thompson (ESFP)",
      riizeNickName: "ZoeGlows",
      riizeUserIcon: "lib/assets/figure/8/p/8_p_2025_06_13_1.png",
      riizeIntroduction:
          "Zoe, a vibrant ESFP, lives for fashion's spotlight moments. Her bold, trendy style turns heads everywhere she goes. She believes clothes should be fun above all else and has never met a bright color or statement accessory she didn't love.",
      riizeSayHi:
          "Hey gorgeous! Just got back from a photoshoot and I'm still feeling the vibe! Don't you just love how the right outfit can make you feel absolutely unstoppable? What makes you feel most confident?",
      riizeShowVideo: "lib/assets/figure/8/v/8_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/8/v/8_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/8/p/8_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/8/p/8_p_2025_06_13_1.png",
        "lib/assets/figure/8/p/8_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Life is a runway, work it!",
      riizeFansCount: 12,
    ),
    "9": Character(
      riizeUserId: "9",
      riizeUserName: "Harper Davis (ISFJ)",
      riizeNickName: "KindlyStylish",
      riizeUserIcon: "lib/assets/figure/9/p/9_p_2025_06_13_1.png",
      riizeIntroduction:
          "ISFJ Harper has a nurturing approach to fashion. She gravitates toward comfortable, practical pieces that still look put-together. She remembers everyone's style preferences and often shops with others in mind, finding joy in helping friends look their best.",
      riizeSayHi:
          "Hi there! I noticed that shade of blue really brings out your eyes! I just finished knitting a scarf for my friend's birthday - I love creating pieces that make people feel special. How's your day going?",
      riizeShowVideo: "lib/assets/figure/9/v/9_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/9/v/9_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/9/p/9_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/9/p/9_p_2025_06_13_1.png",
        "lib/assets/figure/9/p/9_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Dress kindly, for yourself and others.",
      riizeFansCount: 8,
    ),
    "10": Character(
      riizeUserId: "10",
      riizeUserName: "Luna Park (INTP)",
      riizeNickName: "LogicalLuna",
      riizeUserIcon: "lib/assets/figure/10/p/10_p_2025_06_13_1.png",
      riizeIntroduction:
          "INTP Luna sees fashion as a fascinating system to analyze. She's interested in the psychology of style choices and often conducts personal experiments with her wardrobe. Her unconventional combinations reflect her logical yet creative thought process.",
      riizeSayHi:
          "Interesting to meet you. I've been testing a hypothesis about how color psychology affects social interactions. Have you noticed how people respond differently to you based on what you wear? The data is quite compelling.",
      riizeShowVideo: "lib/assets/figure/10/v/10_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/10/v/10_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/10/p/10_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/10/p/10_p_2025_06_13_1.png",
        "lib/assets/figure/10/p/10_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Question style norms, create new ones.",
      riizeFansCount: 5,
    ),
    "11": Character(
      riizeUserId: "11",
      riizeUserName: "Grace Wilson (ESFJ)",
      riizeNickName: "GracefulStyle",
      riizeUserIcon: "lib/assets/figure/11/p/11_p_2025_06_13_1.png",
      riizeIntroduction:
          "As an ESFJ, Grace values harmony in fashion. Her polished, appropriate-for-every-occasion style helps her fit in while standing out just enough. She's attuned to social expectations and trends, using fashion to create connection and belonging.",
      riizeSayHi:
          "Hello dear! I just hosted a clothing swap with friends - such a wonderful way to refresh our wardrobes and spend quality time together! Would you like some style suggestions? You have such lovely features to work with!",
      riizeShowVideo: "lib/assets/figure/11/v/11_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/11/v/11_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/11/p/11_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/11/p/11_p_2025_06_13_1.png",
        "lib/assets/figure/11/p/11_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Style brings people together.",
      riizeFansCount: 11,
    ),
    "12": Character(
      riizeUserId: "12",
      riizeUserName: "Ruby Anderson (ESTP)",
      riizeNickName: "BoldRuby",
      riizeUserIcon: "lib/assets/figure/12/p/12_p_2025_06_13_1.png",
      riizeIntroduction:
          "ESTP Ruby lives for fashion's thrill. Her bold style reflects her risk-taking personality - she's often the first to try daring trends. She shops impulsively, drawn to pieces that make an immediate impact and help her stand out in any crowd.",
      riizeSayHi:
          "Hey! Just scored these amazing platform boots at a sample sale - had to elbow my way through the crowd but totally worth it! What's the most daring fashion choice you've made lately? Life's too short to blend in!",
      riizeShowVideo: "lib/assets/figure/12/v/12_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/12/v/12_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/12/p/12_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/12/p/12_p_2025_06_13_1.png",
        "lib/assets/figure/12/p/12_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Take the risk or lose the chance.",
      riizeFansCount: 10,
    ),
    "13": Character(
      riizeUserId: "13",
      riizeUserName: "Lily Brown (INFJ)",
      riizeNickName: "SoulfulStyle",
      riizeUserIcon: "lib/assets/figure/13/p/13_p_2025_06_13_1.png",
      riizeIntroduction:
          "INFJ Lily sees fashion as a form of quiet self-expression. Her thoughtfully curated wardrobe reflects her complex inner world. She's drawn to pieces with meaning and history, preferring quality items that align with her values and ethical standards.",
      riizeSayHi:
          "Hello... It's nice to connect with you. I was just reading about sustainable textile innovations. There's something beautiful about wearing clothes that honor both creativity and our responsibility to the planet, don't you think?",
      riizeShowVideo: "lib/assets/figure/13/v/13_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/13/v/13_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/13/p/13_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/13/p/13_p_2025_06_13_1.png",
        "lib/assets/figure/13/p/13_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Wear your values, silently speak your truth.",
      riizeFansCount: 7,
    ),
    "14": Character(
      riizeUserId: "14",
      riizeUserName: "Natalie Lee (ISTP)",
      riizeNickName: "CraftyCool",
      riizeUserIcon: "lib/assets/figure/14/p/14_p_2025_06_13_1.png",
      riizeIntroduction:
          "ISTP Natalie has a hands-on approach to fashion. She's skilled at modifying and repairing clothes, often customizing pieces to suit her practical yet distinctive style. She values functionality but adds unexpected details that reflect her technical creativity.",
      riizeSayHi:
          "Hey. Just finished modifying these vintage jeans with some reinforced stitching and hidden pockets. I like making things work better. What practical improvements would you add to your favorite clothes if you could?",
      riizeShowVideo: "lib/assets/figure/14/v/14_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/14/v/14_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/14/p/14_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/14/p/14_p_2025_06_13_1.png",
        "lib/assets/figure/14/p/14_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Function first, style always.",
      riizeFansCount: 6,
    ),
    "15": Character(
      riizeUserId: "15",
      riizeUserName: "Victoria Taylor (ESTJ)",
      riizeNickName: "OrganizedVic",
      riizeUserIcon: "lib/assets/figure/15/p/15_p_2025_06_13_1.png",
      riizeIntroduction:
          "ESTJ Victoria approaches fashion with efficiency and structure. Her wardrobe is organized by occasion, season, and color. She values traditional styles with modern updates and believes in dressing appropriately for every situation - fashion with purpose and clear rules.",
      riizeSayHi:
          "Good day! I've just finished my seasonal wardrobe rotation - everything cataloged and ready for the coming months. Have you prepared your outfits for the upcoming events? Proper planning prevents fashion emergencies!",
      riizeShowVideo: "lib/assets/figure/15/v/15_v_2025_06_13_1.mp4",
      riizeShowVideoArray: ["lib/assets/figure/15/v/15_v_2025_06_13_1.mp4"],
      riizeShowPhoto: "lib/assets/figure/15/p/15_p_2025_06_13_1.png",
      riizeShowPhotoArray: [
        "lib/assets/figure/15/p/15_p_2025_06_13_1.png",
        "lib/assets/figure/15/p/15_p_2025_06_13_2.png"
      ],
      riizeShowMotto: "Order creates opportunity.",
      riizeFansCount: 8,
    ),
  };

  // 获取所有角色列表
  static List<Character> getAllCharacters() {
    return characters.values.toList();
  }

  // 根据ID获取角色
  static Character? getCharacterById(String id) {
    return characters[id];
  }

  // 获取角色数据的JSON字符串
  static String getCharactersJsonString() {
    final Map<String, dynamic> jsonMap = {};
    characters.forEach((key, value) {
      jsonMap[key] = value.toJson();
    });
    return jsonEncode(jsonMap);
  }
}
