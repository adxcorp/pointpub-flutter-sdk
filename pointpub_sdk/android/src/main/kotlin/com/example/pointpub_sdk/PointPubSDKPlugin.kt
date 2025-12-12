package com.example.pointpub_sdk

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

import android.app.Activity

import kr.pointpub.sdk.PointPub
import kr.pointpub.sdk.external.ApiInterface
import kr.pointpub.sdk.external.OfferWallListener
import kr.pointpub.sdk.external.VirtualPointListener

/** PointPubSDKPlugin */
class PointPubSDKPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware {

    private object Methods {
        const val SET_APP_ID = "setAppId"
        const val SET_USER_ID = "setUserId"
        const val START_OFFER_WALL = "startOfferWall"
        const val GET_VIRTUAL_POINT = "getVirtualPoint"
        const val SPEND_VIRTUAL_POINT = "spendVirtualPoint"
        const val GET_COMPLETED_CAMPAIGN = "getCompletedCampaign"
    }

    private lateinit var channel: MethodChannel
    private var eventSink: EventChannel.EventSink? = null
    private var eventChannel: EventChannel? = null
    private var activity: Activity? = null

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
        when(call.method) {
            Methods.SET_APP_ID -> {
                val appId = call.argument<String>("appId") ?: run {
                    result.error("INVALID_ARGUMENT", "appId is required", null)
                    return
                }

                PointPub.setAppId(appId)
                result.success(null)
            }
            Methods.SET_USER_ID -> {
                val userId = call.argument<String>("userId") ?: run {
                    result.error("INVALID_ARGUMENT", "userId is required", null)
                    return
                }
                PointPub.setUserId(userId)
                result.success(null)
            }
            Methods.START_OFFER_WALL -> withActivity(result) { activity ->
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
                        result.success(mapOf(
                            "pointName" to pointName,
                            "point" to remainingPoint
                        ))
                    }

                    override fun onFailure(reason: String) {
                        result.error("FAILURE", reason, null)
                    }
                })
            }
            Methods.SPEND_VIRTUAL_POINT -> withActivity(result) { activity ->
                val point = call.argument<Number>("point")?.toLong() ?: run {
                    result.error("INVALID_ARGUMENT", "point is required", null)
                    return
                }

                PointPub.spendVirtualPoint(activity, point, object : VirtualPointListener {
                    override fun onSuccess(pointName: String, remainingPoint: Long) {
                        result.success(mapOf(
                            "pointName" to pointName,
                            "point" to remainingPoint
                        ))
                    }

                    override fun onFailure(reason: String) {
                        result.error("FAILURE", reason, null)
                    }
                })
            }
            Methods.GET_COMPLETED_CAMPAIGN -> withActivity(result) { activity ->
                PointPub.getParticipation(activity, apiInterface = object : ApiInterface {
                    override fun onResponse(code: Int, data: String) {
                        result.success(data)
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
            result.error("NO_ACTIVITY", "Activity is null", null)
            return
        }
        block(activity)
    }
}
