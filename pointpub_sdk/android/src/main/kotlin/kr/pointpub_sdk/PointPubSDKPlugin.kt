package kr.pointpub_sdk

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

import android.app.Activity
import android.util.Log

import kr.pointpub.sdk.PointPub
import kr.pointpub.sdk.external.ApiInterface
import kr.pointpub.sdk.external.OfferWallListener
import kr.pointpub.sdk.external.VirtualPointListener

/** PointPubSDKPlugin */
final class PointPubSDKPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware {

  private object Methods {
    const val SET_APP_ID = "setAppId"
    const val SET_USER_ID = "setUserId"
    const val START_OFFER_WALL = "startOfferWall"
    const val GET_VIRTUAL_POINT = "getVirtualPoint"
    const val SPEND_VIRTUAL_POINT = "spendVirtualPoint"
    const val GET_COMPLETED_CAMPAIGN = "getCompletedCampaign"
  }

  private object ErrorCode {
    const val SET_APP_ID_FAILED = "SET_APP_ID_FAILED"
    const val SET_USER_ID_FAILED = "SET_USER_ID_FAILED"
    const val GET_ACTIVITY_FAILED = "GET_ACTIVITY_FAILED"
    const val GET_VIRTUAL_POINT_FAILED = "GET_VIRTUAL_POINT_FAILED"
    const val SPEND_VIRTUAL_POINT_FAILED = "SPEND_VIRTUAL_POINT_FAILED"
    const val GET_COMPLETED_CAMPAIGN_FAILED = "GET_COMPLETED_CAMPAIGN_FAILED"
  }

  private object ErrorMessage {
    const val MISSING_APP_ID = "[PointPub_Plugin] Missing appId: The 'appId' argument was not provided or is empty"
    const val MISSING_USER_ID = "[PointPub_Plugin] Missing userId: The 'userId' argument was not provided or is empty"
    const val MISSING_POINT = "[PointPub_Plugin] Missing point: The 'point' argument was not provided or is empty. Pass a positive integer value for 'point' to spendVirtualPoint"
    const val INVALID_PRESENTATION_CONTEXT = "[PointPub_Plugin] Invalid presentation context: Activity is null or not in a valid lifecycle state. Call startOfferWall after the Activity is fully created and resumed"
  }

  private final var logName = "[PointPub_Plugin]"
  private lateinit var channel: MethodChannel
  private var eventSink: EventChannel.EventSink? = null
  private var eventChannel: EventChannel? = null
  private var activity: Activity? = null
  private var appId: String = ""
  private var userId: String = ""

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "pointpub_sdk")
    channel.setMethodCallHandler(this)

    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "pointpub_sdk/events")
    eventChannel?.setStreamHandler(this)
  }

  // Method Channel
  override fun onMethodCall(
    call: MethodCall,
    result: Result
  ) {
    Log.d(logName, "call.method: $call.method")

    when (call.method) {
      Methods.SET_APP_ID -> {
        val appId = call.argument<String>("appId") ?: run {
          result.error(ErrorCode.SET_APP_ID_FAILED, ErrorMessage.MISSING_APP_ID, null)
          return
        }
        this.appId = appId
        PointPub.setAppId(appId)
        result.success(null)
      }

      Methods.SET_USER_ID -> {
        val userId = call.argument<String>("userId") ?: run {
          result.error(ErrorCode.SET_USER_ID_FAILED, ErrorMessage.MISSING_USER_ID, null)
          return
        }
        this.userId = userId
        PointPub.setUserId(userId)
        result.success(null)
      }

      Methods.START_OFFER_WALL -> withActivity(result) { activity ->
        call.argument<String>("pluginVersion")?.let { pluginVersion ->
          call.argument<String>("sdkVersion")?.let { sdkVersion ->
            Log.d(logName, "pluginVersion: $pluginVersion, sdkVersion: $sdkVersion, appId: $appId, userId: $userId")
          }
        }

        PointPub.startOfferWall(activity, object : OfferWallListener {
          override fun onOpened() {
            eventSink?.success(mapOf("event" to "onOpenOfferWall"))
          }

          override fun onClosed() {
            eventSink?.success(mapOf("event" to "onCloseOfferWall"))
          }
        })
        result.success(null)
      }

      Methods.GET_VIRTUAL_POINT -> withActivity(result) { activity ->
        PointPub.getVirtualPoint(activity, object : VirtualPointListener {
          override fun onSuccess(pointName: String, remainingPoint: Long) {
            result.success(
              mapOf(
                "pointName" to pointName,
                "point" to remainingPoint
              )
            )
          }

          override fun onFailure(reason: String) {
            result.error(ErrorCode.GET_VIRTUAL_POINT_FAILED, reason, null)
          }
        })
      }

      Methods.SPEND_VIRTUAL_POINT -> withActivity(result) { activity ->
        val point = call.argument<Number>("point")?.toLong() ?: run {
          result.error(ErrorCode.SPEND_VIRTUAL_POINT_FAILED, ErrorMessage.MISSING_POINT, null)
          return
        }

        PointPub.spendVirtualPoint(activity, point, object : VirtualPointListener {
          override fun onSuccess(pointName: String, remainingPoint: Long) {
            result.success(
              mapOf(
                "pointName" to pointName,
                "point" to remainingPoint
              )
            )
          }

          override fun onFailure(reason: String) {
            result.error(ErrorCode.SPEND_VIRTUAL_POINT_FAILED, reason, null)
          }
        })
      }

      Methods.GET_COMPLETED_CAMPAIGN -> withActivity(result) { activity ->
        PointPub.getParticipation(activity, apiInterface = object : ApiInterface {
          override fun onResponse(code: Int, data: String) {
            if (code == 0) {
              result.success(data)
            } else {
              result.error(ErrorCode.GET_COMPLETED_CAMPAIGN_FAILED, data, null)
            }
          }
        })
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  // Event Channel
  override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  // ActivityAware
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  // Helper
  private inline fun withActivity(
    result: Result,
    block: (Activity) -> Unit
  ) {
    val activity = activity ?: run {
      result.error(ErrorCode.GET_ACTIVITY_FAILED, ErrorMessage.INVALID_PRESENTATION_CONTEXT, null)
      return
    }
    block(activity)
  }
}
