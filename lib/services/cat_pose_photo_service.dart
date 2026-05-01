/// 貓咪姿勢拍照服務
/// v1：封裝照片路徑儲存，未來可擴展為 CatPoseRecord 或本地資料庫
class CatPosePhotoService {
  /// 儲存姿勢照片路徑
  /// v1 目前只回傳 imagePath，未來可擴展寫入 SharedPreferences 或 SQLite
  Future<String?> savePosePhotoPath(String imagePath) async {
    // v1：直接回傳路徑，未來可在這裡擴展：
    // - 寫入 SharedPreferences
    // - 寫入 SQLite 本地資料庫
    // - 建立 CatPoseRecord 並持久化
    if (imagePath.isEmpty) {
      return null;
    }
    return imagePath;
  }

  /// 取得已保存的照片路徑列表
  /// v1 預留，未來擴展用
  Future<List<String>> getSavedPhotoPaths() async {
    // v1：待擴展
    return [];
  }

  /// 刪除指定的照片路徑
  /// v1 預留，未來擴展用
  Future<bool> deletePhotoPath(String imagePath) async {
    // v1：待擴展
    return true;
  }
}
