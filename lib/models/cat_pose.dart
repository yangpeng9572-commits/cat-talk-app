/// 貓咪姿勢/行為模型
class CatPose {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final CatPoseCategory category;
  final String mood;
  final String advice;
  final String emotionalInsight;

  const CatPose({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.category,
    required this.mood,
    required this.advice,
    required this.emotionalInsight,
  });
}

/// 姿勢分類
enum CatPoseCategory {
  resting('🐱', '休息姿勢'),
  daily('✨', '日常行為'),
  alert('👀', '警戒/情緒'),
  play('🎾', '玩耍/狩獵'),
  affectionate('💕', '親密行為'),
  uncomfortable('😿', '不舒適/緊張'),
  eating('🍽', '進食相關'),
  social('🐾', '社交行為');

  final String emoji;
  final String label;

  const CatPoseCategory(this.emoji, this.label);
}

/// 完整貓咪姿勢庫
class CatPoseLibrary {
  static const List<CatPose> allPoses = [
    // ===== 休息姿勢 =====
    CatPose(
      id: 'side_lying',
      emoji: '😴',
      name: '側躺休息',
      description: '身體側躺，四肢放鬆伸展',
      category: CatPoseCategory.resting,
      mood: '放鬆安心',
      advice: '這是貓咪最放鬆的姿勢之一，代表她對環境感到安心 💕',
      emotionalInsight: '側躺並露出肚子是信任的表現，貓咪這時完全放鬆，願意把自己最脆弱的部位露出來。',
    ),
    CatPose(
      id: 'curled_up',
      emoji: '🥐',
      name: '蜷曲入睡',
      description: '身體蜷成一團，頭埋在尾巴或身體下',
      category: CatPoseCategory.resting,
      mood: '保暖、警戒',
      advice: '這個姿勢可能在保暖，也可能保持輕度警戒，天冷時常見 🥰',
      emotionalInsight: '蜷曲可以保暖，也讓貓咪在放鬆的同時保持快速反應的能力。',
    ),
    CatPose(
      id: 'on_back',
      emoji: '🤹',
      name: '仰躺露肚',
      description: '四腳朝天躺在地上，露出肚子',
      category: CatPoseCategory.resting,
      mood: '完全信任',
      advice: '這是信任的最高表現！你的貓咪對你完全放心 🐾',
      emotionalInsight: '肚子是貓咪最脆弱的部位，仰躺露肚表示她相信你不會傷害她。',
    ),
    CatPose(
      id: 'loaf',
      emoji: '🍞',
      name: '麵包睡姿',
      description: '身體趴下，四肢收在身體下面，像一條胖麵包',
      category: CatPoseCategory.resting,
      mood: '放鬆但警覺',
      advice: '這個姿勢方便隨時起身，代表她正在休息但保持輕度警覺 🍞',
      emotionalInsight: '「麵包」姿勢是一種平衡狀態，介於完全放鬆和警戒之間。',
    ),
    CatPose(
      id: 'standing_sleep',
      emoji: '🤭',
      name: '站著打瞌睡',
      description: '站著但頭低垂，眼睛半閉',
      category: CatPoseCategory.resting,
      mood: '輕度疲憊',
      advice: '她有點累了但不想完全躺下，可能是在顧門口或在觀察什麼 🤔',
      emotionalInsight: '這個姿勢讓貓咪可以快速行動，通常出現在她覺得需要保持警戒但又很累的時候。',
    ),

    // ===== 日常行為 =====
    CatPose(
      id: 'stretching',
      emoji: '🧘',
      name: '伸懶腰',
      description: '前身趴低，屁股翹高，前後腿伸展',
      category: CatPoseCategory.daily,
      mood: '清醒、舒服',
      advice: '她在喚醒身體！這個伸展動作能活化肌肉，代表她睡醒了或休息夠了 ✨',
      emotionalInsight: '伸懶腰表示貓咪身心舒暢，放鬆後的自然反應。伸懶腰也幫助血液循環。',
    ),
    CatPose(
      id: 'grooming',
      emoji: '🫧',
      name: '舔毛',
      description: '用舌頭仔細梳理自己的毛髮',
      category: CatPoseCategory.daily,
      mood: '放鬆、整理思緒',
      advice: '這是她的「自我時間」，在整理毛髮也是在冷靜自己 🫧',
      emotionalInsight: '舔毛是貓咪最常見的安撫行為，吃飯後、放鬆時、或緊張後都可能會舔毛。',
    ),
    CatPose(
      id: 'yawning',
      emoji: '😴',
      name: '打哈欠',
      description: '嘴巴大張，深深打一個哈欠',
      category: CatPoseCategory.daily,
      mood: '釋放氧氣、緩解壓力',
      advice: '她在給自己充氧！打哈欠也是緩解緊張的一種方式 😽',
      emotionalInsight: '貓咪打哈欠不只是睏了，也可能是面對壓力時的自然反應，用來讓自己冷靜下來。',
    ),
    CatPose(
      id: 'kneading',
      emoji: '🍞',
      name: '揉麵包',
      description: '用前腳掌交替按壓柔軟的物品（毯子、墊子、或你的身上）',
      category: CatPoseCategory.daily,
      mood: '滿足、幸福',
      advice: '這是幼貓時期的本能！她在回味喝奶時的幸福記憶 💕',
      emotionalInsight: '揉麵包是貓咪最甜蜜的本能之一，代表她把你當成媽媽一樣信任和依戀。',
    ),
    CatPose(
      id: 'scratching',
      emoji: '🪵',
      name: '抓撓',
      description: '用爪子抓撓傢俱或貓抓板',
      category: CatPoseCategory.daily,
      mood: '標記領土、伸展',
      advice: '她不只是在磨爪子，還在標記領土和伸展肌肉 🪵',
      emotionalInsight: '爪子是貓咪的領土標記工具，抓撓會留下氣味和視覺痕跡，宣示「這是我的地盤」。',
    ),
    CatPose(
      id: 'tail_twitch',
      emoji: '🐈',
      name: '尾巴輕擺',
      description: '尾巴尖端輕輕來回擺動',
      category: CatPoseCategory.daily,
      mood: '專注、好奇',
      advice: '她在專注！尾巴輕擺通常表示她對某件事物非常感興趣 👀',
      emotionalInsight: '尾巴是貓咪情緒的晴雨表。輕微擺動代表好奇和專注，這時她在認真觀察獵物或有趣的事物。',
    ),

    // ===== 警戒/情緒 =====
    CatPose(
      id: 'ears_forward',
      emoji: '👂',
      name: '耳朵向前',
      description: '兩隻耳朵豎直向前，頭抬高',
      category: CatPoseCategory.alert,
      mood: '好奇、興趣',
      advice: '她對什麼東西很感興趣！耳朵向前是最積極的「傾聽」姿勢 🎧',
      emotionalInsight: '耳朵向前表示貓咪對環境中的某個聲音或事物產生濃厚的興趣，正積極收集資訊。',
    ),
    CatPose(
      id: 'airplane_ears',
      emoji: '✈️',
      name: '飛機耳',
      description: '耳朵向兩側壓平，像飛機翅膀',
      category: CatPoseCategory.alert,
      mood: '緊張、害怕',
      advice: '她有點緊張！這個姿勢代表她感到威脅或不確定的威脅存在 😿',
      emotionalInsight: '飛機耳是明顯的防禦信號，表示貓咪感到害怕或準備保護自己。這時應給她空間。',
    ),
    CatPose(
      id: 'tail_up',
      emoji: '🚩',
      name: '尾巴豎直向上',
      description: '尾巴笔直向上，尾尖可能微微彎曲',
      category: CatPoseCategory.alert,
      mood: '開心問候',
      advice: '這是貓咪的「嗨！你好！」姿勢！她在向你打招呼呢 🐱',
      emotionalInsight: '尾巴向上是貓咪最友善的信號之一，代表她心情愉快、見到你很開心。尾尖彎曲像問號，是親密的表示。',
    ),
    CatPose(
      id: 'puffed_tail',
      emoji: '🦨',
      name: '尾巴炸毛',
      description: '尾巴毛髮豎起，整條尾巴變得蓬鬆',
      category: CatPoseCategory.alert,
      mood: '極度害怕',
      advice: '她非常害怕！這是她的「讓我看起來更大」的防禦反應 🚨',
      emotionalInsight: '炸毛讓貓咪看起來更大，試圖嚇退威脅。這時千萬不要靠近或追逐她。',
    ),
    CatPose(
      id: 'dilated_pupils',
      emoji: '👁️',
      name: '瞳孔放大',
      description: '眼睛黑眼球變得很大',
      category: CatPoseCategory.alert,
      mood: '興奮或害怕',
      advice: '取決於其他肢體語言！大瞳孔可能代表強烈興趣或極度恐懼 👀',
      emotionalInsight: '在昏暗環境中瞳孔放大是正常的，但在明亮環境下放大通常代表情緒激動——可能是興奮玩耍，也可能是害怕。',
    ),
    CatPose(
      id: 'constricted_pupils',
      emoji: '🔴',
      name: '瞳孔縮小',
      description: '眼睛瞳孔變成一條細線',
      category: CatPoseCategory.alert,
      mood: '攻擊性、威脅',
      advice: '這個姿勢可能代表攻擊性！要小心處理 ⚠️',
      emotionalInsight: '細長的瞳孔在明亮環境下出現，通常代表攻擊性或領土防御。建議保持距離。',
    ),
    CatPose(
      id: 'arched_back',
      emoji: '😾',
      name: '弓背炸毛',
      description: '背部拱起，毛髮全部豎立',
      category: CatPoseCategory.alert,
      mood: '極度恐懼',
      advice: '她在試圖讓自己看起來更大更可怕，千萬不要突然動作嚇到她 😿',
      emotionalInsight: '這是典型的防禦姿勢，貓咪在說「我不喜歡這個，請離我遠一點」。這時最好的回應是保持距離。',
    ),
    CatPose(
      id: 'hissing',
      emoji: '😾',
      name: '嘶嘶叫',
      description: '嘴巴張開，發出嘶嘶聲',
      category: CatPoseCategory.alert,
      mood: '恐懼、防禦',
      advice: '這是最後警告！她已經非常不舒服了，請立刻給她空間 🚨',
      emotionalInsight: '嘶嘶聲是貓咪的「退後！」信號，代表她感到威脅並準備反擊。這時千萬不要伸手。',
    ),

    // ===== 玩耍/狩獵 =====
    CatPose(
      id: 'ambush',
      emoji: '🐆',
      name: '伏擊姿勢',
      description: '身體壓低，屁股左右搖擺，準備衝刺',
      category: CatPoseCategory.play,
      mood: '狩獵本能',
      advice: '她是個小小獵手！這個搖擺是在蓄積力量，準備爆發一場狩獵 🎯',
      emotionalInsight: '屁股搖擺是貓咪內建的獵捕本能，看起來可愛但其實是認真的狩獵準備動作。',
    ),
    CatPose(
      id: 'hip_kicks',
      emoji: '🥊',
      name: '後腿踢',
      description: '仰躺時用後腿在空中踢蹬',
      category: CatPoseCategory.play,
      mood: '玩得開心',
      advice: '她正在享受激烈的玩耍時間！這是貓咪練習自衛技能的方式 🥊',
      emotionalInsight: '後腿踢是貓咪的防禦本能，在野外用來對抗更大的獵食者。室內貓通常在玩得忘我時才會使出這招。',
    ),
    CatPose(
      id: 'chasing',
      emoji: '🏃',
      name: '追逐中',
      description: '突然暴衝，在家裡瘋狂奔跑',
      category: CatPoseCategory.play,
      mood: '精力充沛',
      advice: '她有太多精力需要釋放！這是健康的行為，Zoomies 是緩解積累能量的方式 🏃',
      emotionalInsight: '這種瘋狂奔跑到處跑的行為俗稱「Zoomies」，通常是貓咪在釋放被抑制的能量，或是上完廁所後感到輕鬆愉悅。',
    ),
    CatPose(
      id: 'pouncing',
      emoji: '🐱',
      name: '猛撲',
      description: '壓低身體，突然向獵物或玩具撲過去',
      category: CatPoseCategory.play,
      mood: '狩獵樂趣',
      advice: '她是狩獵高手！這個動作是在練習精準打擊 🎯',
      emotionalInsight: '猛撲是貓咪最標誌性的狩獵行為，即使家貓不需要狩獵也會保留這個本能，是很好的運動和智力遊戲。',
    ),
    CatPose(
      id: 'chirp',
      emoji: '🐦',
      name: '嘰嘰叫',
      description: '發出短促、興奮的顫音，像鳥叫',
      category: CatPoseCategory.play,
      mood: '興奮、渴望',
      advice: '她在對窗外的鳥或昆蟲表達興奮！這是強烈興趣的信號 🐦',
      emotionalInsight: '嘰嘰叫是貓咪看到獵物時的沮喪反應，嘴巴開合顫抖的叫聲代表「我好想要那個！」的強烈渴望。',
    ),

    // ===== 親密行為 =====
    CatPose(
      id: 'head_bunting',
      emoji: '💋',
      name: '磨蹭頭',
      description: '用頭反覆磨蹭你的臉、腿或物品',
      category: CatPoseCategory.affectionate,
      mood: '撒嬌、標記',
      advice: '她在把自己氣味留給你！這是貓咪說「你是我的人」的方式 💕',
      emotionalInsight: '貓咪臉頰和下巴有氣味腺，用頭磨蹭是在把氣味留在你身上，同時也收集你的氣味，是建立共同氣味群的亲密行為。',
    ),
    CatPose(
      id: 'slow_blink',
      emoji: '😽',
      name: '慢慢眨眼',
      description: '溫柔地對你緩慢眨眼，眼睛半閉',
      category: CatPoseCategory.affectionate,
      mood: '愛你、信任',
      advice: '這是貓咪的「我愛你」！試著對她慢慢眨眼回應吧 💕',
      emotionalInsight: '慢慢眨眼被稱為「貓咪之吻」，是信任和愛意的終極表達。專家建議可以對著貓咪慢慢眨眼來建立親密關係。',
    ),
    CatPose(
      id: 'licking',
      emoji: '👅',
      name: '舔人',
      description: '用舌頭溫柔地舔你的皮膚或頭髮',
      category: CatPoseCategory.affectionate,
      mood: '照顧、認同',
      advice: '她把你當成家人了！這是在幫你梳毛，代表她非常愛你 👅',
      emotionalInsight: '在貓咪社會裡，互相梳毛是建立社會連結的行為。當她舔你時，她把你視為家庭成員，在表達照顧和認同。',
    ),
    CatPose(
      id: 'sleeping_on_you',
      emoji: '💤',
      name: '睡在你身上',
      description: '選擇睡在你的腿上、胸口或旁邊',
      category: CatPoseCategory.affectionate,
      mood: '完全信任',
      advice: '這是信任的最高表現！能睡在你身上代表她覺得你非常安全 💤',
      emotionalInsight: '貓咪睡覺時最脆弱，選擇睡在你身邊代表她完全信任你，覺得和你在一起最安心。有時候睡在腿上也是想要取暖。',
    ),
    CatPose(
      id: 'bringing_gifts',
      emoji: '🎁',
      name: '送禮物',
      description: '叼著玩具、老鼠或其他「獵物」送給你',
      category: CatPoseCategory.affectionate,
      mood: '分享、照顧',
      advice: '她在向你分享獵物！雖然有點嚇人，但這是她愛的表現 🎁',
      emotionalInsight: '母貓會把獵物帶回窩給小貓，家貓把「禮物」帶給你是表示照顧和愛意。也有可能是她在炫耀自己的狩獵成果。',
    ),
    CatPose(
      id: 'following',
      emoji: '🚶',
      name: '跟著你',
      description: '你走到哪她就跟到哪',
      category: CatPoseCategory.affectionate,
      mood: '依戀、好奇',
      advice: '她是你的小影子！代表她非常喜歡你，想和你在一起 🚶',
      emotionalInsight: '貓咪跟隨行為代表依戀和安全依附。她想參與你的每一個活動，因為你是她生活中最重要的人。',
    ),

    // ===== 不舒適/緊張 =====
    CatPose(
      id: 'hiding',
      emoji: '🙈',
      name: '躲藏',
      description: '躲在盒子、角落、床底或其他狹小空間',
      category: CatPoseCategory.uncomfortable,
      mood: '害怕、尋求安全感',
      advice: '她需要安全感！狹小的空間讓她覺得受到保護，讓她獨處一下 🙈',
      emotionalInsight: '躲藏是貓咪最基本的防禦機制。當感到威脅或壓力時，躲進狹小空間能讓她感到安全。這時應給她空間而非把她拉出來。',
    ),
    CatPose(
      id: 'tail_flick',
      emoji: '⚡',
      name: '用力甩尾巴',
      description: '尾巴用力、快速地來回甩動',
      category: CatPoseCategory.uncomfortable,
      mood: '不滿、緊張',
      advice: '她不高興了！尾巴快速甩動表示她感到不耐煩或緊張 ⚡',
      emotionalInsight: '不同於尾巴輕擺表示好奇，用力甩尾巴是明顯的負面情緒信號。仔細觀察她的其他肢體語言來判斷具體原因。',
    ),
    CatPose(
      id: 'creeping',
      emoji: '🐈‍⬛',
      name: '壓低身體行走',
      description: '身體幾乎貼地，悄悄移動',
      category: CatPoseCategory.uncomfortable,
      mood: '害怕、潛行',
      advice: '她在試圖不被發現！這個姿勢代表她感到威脅或不想引起注意 🙈',
      emotionalInsight: '壓低身體行走是獵物動物避免被發現的本能表現。這可能是家中有其他寵物或小孩讓她感到威脅。',
    ),
    CatPose(
      id: 'excessive_meowing',
      emoji: '🗣️',
      name: '過度喵喵叫',
      description: '持續不斷地大聲喵喵叫',
      category: CatPoseCategory.uncomfortable,
      mood: '需求、緊張',
      advice: '她在試圖告訴你什麼！可能是餓了、身體不舒服、或需要關注 🗣️',
      emotionalInsight: '成年貓之間不常使用喵喵叫溝通，對人喵喵叫是貓咪特別發展出的「和人類說話」的方式。持續叫可能是在表達需求或不舒服。',
    ),
    CatPose(
      id: 'overgrooming',
      emoji: '🪮',
      name: '過度理毛',
      description: '不斷重複舔同一個部位',
      category: CatPoseCategory.uncomfortable,
      mood: '壓力、焦慮',
      advice: '這可能是緊張的表現！強迫性的理毛可能是焦慮或皮膚問題的徵兆 🪮',
      emotionalInsight: '過度理毛是一種「置換行為」，類似人類的緊張時摳指甲。如果發現她一直舔同一個地方，建議帶去看獸醫檢查是否有皮膚問題。',
    ),

    // ===== 進食相關 =====
    CatPose(
      id: 'eating',
      emoji: '🍽️',
      name: '正在吃飯',
      description: '低頭吃食物或點心',
      category: CatPoseCategory.eating,
      mood: '滿足、飢餓',
      advice: '她在補充能量！吃飯是維持生命的基本行為 🍽️',
      emotionalInsight: '野外的貓咪是獨行獵人，吃飯時會保持警戒。如果她能在你面前安心吃飯，代表她對你非常信任。',
    ),
    CatPose(
      id: 'sniffing_food',
      emoji: '👃',
      name: '聞食物',
      description: '用鼻子嗅聞食物但不急著吃',
      category: CatPoseCategory.eating,
      mood: '評估、考慮',
      advice: '她在評估這個食物！貓咪嗅覺非常靈敏，這是正常的嗅聞行為 👃',
      emotionalInsight: '貓咪鼻腔有2億個嗅覺受體（人類只有600萬），聞食物是她在收集資訊，判斷食物是否新鮮、可口、安全。',
    ),
    CatPose(
      id: 'drinking',
      emoji: '💧',
      name: '喝水中',
      description: '用舌頭舔水喝',
      category: CatPoseCategory.eating,
      mood: '解渴',
      advice: '她在喝水！保持充足水分對貓咪腎臟健康很重要 💧',
      emotionalInsight: '貓咪是用舌尖勾水的方式喝水，每秒可以舔水4次。如果她喜歡喝水龍頭的水，可能是因為喜歡流動水和新鮮的感覺。',
    ),
    CatPose(
      id: 'begging',
      emoji: '🙃',
      name: '讨食',
      description: '盯著你看、繞著你轉、喵喵叫',
      category: CatPoseCategory.eating,
      mood: '飢餓、想要注意力',
      advice: '她在求投餵！或想要你的關注。可以先檢查是否真的餓了 🙃',
      emotionalInsight: '貓咪很快就學會用各种方式操縱人類給他們食物。有時候喵喵叫不只是因為餓，也可能是想要注意力或零食。',
    ),

    // ===== 社交行為 =====
    CatPose(
      id: 'greeting',
      emoji: '👋',
      name: '打招呼',
      description: '看到你回家時喵喵叫、尾巴向上走過來',
      category: CatPoseCategory.social,
      mood: '開心興奮',
      advice: '她很高興你回來了！這是她說「歡迎回家」的方式 🏠',
      emotionalInsight: '貓咪對出門在外的家人會有「分離焦慮」，看到你回家是牠一天中最期待的時刻之一。',
    ),
    CatPose(
      id: 'meowing',
      emoji: '🗣️',
      name: '對話',
      description: '對你發出叫聲，像是在說話',
      category: CatPoseCategory.social,
      mood: '溝通、需求',
      advice: '她在和你說話！試著回應她，這能增進你們的感情 🗣️',
      emotionalInsight: '研究顯示，貓咪會發展出針對不同人類的不同叫聲。當她對你喵喵叫時，試著回應會讓她感到被理解和重視。',
    ),
    CatPose(
      id: 'staring',
      emoji: '👀',
      name: '凝視',
      description: '盯著你看或其他方向看',
      category: CatPoseCategory.social,
      mood: '好奇、連結',
      advice: '如果是盯著你，是在嘗試和你溝通或了解你的情緒 👀',
      emotionalInsight: '貓咪之間很少長時間凝視（凝視是攻擊的信號），但對人凝視是建立連結和溝通的方式。試著對她慢慢眨眼回應。',
    ),
    CatPose(
      id: 'tail_around',
      emoji: '🔗',
      name: '繞尾巴',
      description: '用尾巴繞著另一隻貓或你的腿',
      category: CatPoseCategory.social,
      mood: '友愛、連結',
      advice: '這是貓咪版的「搭肩」！代表她喜歡對方 🔗',
      emotionalInsight: '尾巴繞在其他貓咪或人類身上是友善和愛意的表達，就像人與人之間的擁抱一樣。這是最甜蜜的肢體語言之一。',
    ),
    CatPose(
      id: 'allogrooming',
      emoji: '🤝',
      name: '互相理毛',
      description: '和其他貓咪互相舔毛',
      category: CatPoseCategory.social,
      mood: '友好、信任',
      advice: '這是貓咪社會的友好行為！互相理毛代表她們是好朋友 🤝',
      emotionalInsight: '貓咪互相理毛（allogrooming）是建立和維持社會關係的行為，通常發生在關係親密的貓咪之間，是友誼的象徵。',
    ),
    CatPose(
      id: 'nose_touch',
      emoji: '👃',
      name: '碰鼻子',
      description: '用鼻子輕碰另一隻貓或你的鼻子/臉',
      category: CatPoseCategory.social,
      mood: '問候、確認',
      advice: '這是貓咪的「你好！很高興見到你！」問候方式 👋',
      emotionalInsight: '貓咪的鼻子碰鼻子等同於人類的問候和確認身份。貓咪鼻腔內的嗅覺系統可以通過這個接觸收集對方的大量資訊。',
    ),
  ];

  /// 取得所有分類
  static List<CatPoseCategory> get categories => CatPoseCategory.values;

  /// 根據分類取得姿勢
  static List<CatPose> getByCategory(CatPoseCategory category) {
    return allPoses.where((pose) => pose.category == category).toList();
  }

  /// 搜尋姿勢
  static List<CatPose> search(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return allPoses.where((pose) =>
      pose.name.toLowerCase().contains(lowerKeyword) ||
      pose.description.toLowerCase().contains(lowerKeyword) ||
      pose.mood.toLowerCase().contains(lowerKeyword)
    ).toList();
  }

  /// 根據 ID 取得姿勢
  static CatPose? getById(String id) {
    try {
      return allPoses.firstWhere((pose) => pose.id == id);
    } catch (e) {
      return null;
    }
  }
}
