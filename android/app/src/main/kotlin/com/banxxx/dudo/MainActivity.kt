package com.banxxx.dudo

import com.ryanheise.audioservice.AudioServiceActivity

/**
 * 必须继承 [AudioServiceActivity]（它本身继承自 FlutterFragmentActivity），
 * 否则 audio_service 插件初始化时会抛
 *   "The Activity class declared in your AndroidManifest.xml is wrong
 *    or has not provided the correct FlutterEngine."
 */
class MainActivity : AudioServiceActivity()
