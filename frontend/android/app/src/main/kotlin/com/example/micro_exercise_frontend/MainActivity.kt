package com.example.micro_exercise_frontend

import com.heytap.databaseengine.HeytapHealthApi
import com.heytap.databaseengine.apiv2.HResponse
import com.heytap.databaseengine.apiv2.auth.AuthResult
import com.heytap.databaseengine.apiv3.DataReadRequest
import com.heytap.databaseengine.apiv3.data.DataPoint
import com.heytap.databaseengine.apiv3.data.DataSet
import com.heytap.databaseengine.apiv3.data.DataType
import com.heytap.databaseengine.apiv3.data.Element
import com.heytap.databaseengine.apiv3.data.Value
import com.heytap.databaseengine.model.proxy.UserDeviceInfoProxy
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.LocalDate
import java.time.ZoneId

class MainActivity : FlutterActivity() {
    private val channelName = "kuibuqianli/oppo_health"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initOppoHealthSdk()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                handleMethodCall(call, result)
            }
    }

    private fun initOppoHealthSdk() {
        runCatching {
            HeytapHealthApi.init(applicationContext)
            HeytapHealthApi.setLoggable(true)
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                runCatching {
                    initOppoHealthSdk()
                    result.success(mapOf("initialized" to true, "sdkVersion" to "2.1.7"))
                }.onFailure { error ->
                    result.error("INIT_FAILED", error.message, null)
                }
            }

            "requestAuthorization" -> requestAuthorization(result)
            "validateAuthorization" -> validateAuthorization(result)
            "revokeAuthorization" -> revokeAuthorization(result)
            "queryBoundDevices" -> queryBoundDevices(result)
            "readTodayDailyActivity" -> readTodayDailyActivity(result)
            "readTodayDailyActivityCount" -> readTodayDailyActivityCount(result)
            "readTodaySportMetadata" -> readTodaySportMetadata(result)
            else -> result.notImplemented()
        }
    }

    private fun requestAuthorization(result: MethodChannel.Result) {
        HeytapHealthApi.getInstance().authorityApi().request(
            this,
            object : HResponse<AuthResult> {
                override fun onSuccess(authResult: AuthResult) {
                    result.success(
                        mapOf(
                            "success" to true,
                            "message" to "authorization_requested",
                        ),
                    )
                }

                override fun onFailure(errorCode: Int) {
                    result.error(
                        "AUTH_REQUEST_FAILED",
                        "requestAuthorization failed: $errorCode",
                        errorCode,
                    )
                }
            },
        )
    }

    private fun validateAuthorization(result: MethodChannel.Result) {
        HeytapHealthApi.getInstance().authorityApi().valid(
            object : HResponse<List<String>> {
                override fun onSuccess(scopeList: List<String>) {
                    result.success(
                        mapOf(
                            "authorized" to scopeList.isNotEmpty(),
                            "scopes" to scopeList,
                        ),
                    )
                }

                override fun onFailure(errorCode: Int) {
                    result.error(
                        "AUTH_VALIDATE_FAILED",
                        "validateAuthorization failed: $errorCode",
                        errorCode,
                    )
                }
            },
        )
    }

    private fun revokeAuthorization(result: MethodChannel.Result) {
        HeytapHealthApi.getInstance().authorityApi().revoke(
            object : HResponse<List<Any>> {
                override fun onSuccess(objectList: List<Any>) {
                    result.success(mapOf("revoked" to true))
                }

                override fun onFailure(errorCode: Int) {
                    result.error(
                        "AUTH_REVOKE_FAILED",
                        "revokeAuthorization failed: $errorCode",
                        errorCode,
                    )
                }
            },
        )
    }

    private fun queryBoundDevices(result: MethodChannel.Result) {
        HeytapHealthApi.getInstance().deviceApi().deviceInfoApi().queryBoundDevice(
            object : HResponse<List<UserDeviceInfoProxy>> {
                override fun onSuccess(userDeviceInfoList: List<UserDeviceInfoProxy>) {
                    result.success(
                        userDeviceInfoList.map { device ->
                            mapOf(
                                "deviceName" to device.deviceName,
                                "deviceType" to device.deviceType,
                                "subDeviceType" to device.subDeviceType,
                                "model" to device.model,
                                "manufacturer" to device.manufacturer,
                                "connectionState" to device.connectionState,
                            )
                        },
                    )
                }

                override fun onFailure(errorCode: Int) {
                    result.error(
                        "QUERY_DEVICES_FAILED",
                        "queryBoundDevices failed: $errorCode",
                        errorCode,
                    )
                }
            },
        )
    }

    private fun readTodayDailyActivity(result: MethodChannel.Result) {
        readDataSets(DataType.TYPE_DAILY_ACTIVITY, result)
    }

    private fun readTodayDailyActivityCount(result: MethodChannel.Result) {
        readDataSets(DataType.TYPE_DAILY_ACTIVITY_COUNT, result)
    }

    private fun readTodaySportMetadata(result: MethodChannel.Result) {
        readDataSets(DataType.TYPE_SPORT_METADATA, result)
    }

    private fun readDataSets(dataType: DataType, result: MethodChannel.Result) {
        val startTime = LocalDate.now()
            .atStartOfDay(ZoneId.systemDefault())
            .toInstant()
            .toEpochMilli()
        val endTime = LocalDate.now()
            .plusDays(1)
            .atStartOfDay(ZoneId.systemDefault())
            .toInstant()
            .toEpochMilli() - 1

        val request = DataReadRequest.Builder()
            .read(dataType)
            .setTimeRange(startTime, endTime)
            .build()

        HeytapHealthApi.getInstance().dataApi().read(
            request,
            object : HResponse<List<DataSet>> {
                override fun onSuccess(dataSets: List<DataSet>) {
                    result.success(
                        mapOf(
                            "dataType" to dataType.name,
                            "startTime" to startTime,
                            "endTime" to endTime,
                            "dataSets" to dataSets.map { dataSet -> dataSet.toMap() },
                        ),
                    )
                }

                override fun onFailure(errorCode: Int) {
                    result.error(
                        "READ_DATA_FAILED",
                        "readDataSets failed for ${dataType.name}: $errorCode",
                        errorCode,
                    )
                }
            },
        )
    }

    private fun DataSet.toMap(): Map<String, Any?> {
        return mapOf(
            "dataType" to dataType.name,
            "points" to dataPoints.map { point -> point.toMap() },
        )
    }

    private fun DataPoint.toMap(): Map<String, Any?> {
        return mapOf(
            "dataType" to dataType.name,
            "startTimeStamp" to startTimeStamp,
            "timeStamp" to timeStamp,
            "step" to getValueOrNull(Element.ELEMENT_STEP)?.asIntSafe(),
            "distance" to getValueOrNull(Element.ELEMENT_DISTANCE)?.asIntSafe(),
            "calorie" to getValueOrNull(Element.ELEMENT_CALORIE)?.asIntSafe(),
            "moveTime" to getValueOrNull(Element.ELEMENT_MOVE_TIME)?.asIntSafe(),
            "workMinute" to getValueOrNull(Element.ELEMENT_WORK_MINUTE)?.asIntSafe(),
            "sportMode" to getValueOrNull(Element.ELEMENT_SPORT_MODE)?.asIntSafe(),
            "duration" to getValueOrNull(Element.ELEMENT_DURATION)?.asIntSafe(),
            "avgHeartRate" to getValueOrNull(Element.ELEMENT_AVG_HEART_RATE)?.asIntSafe(),
            "deviceCategory" to getValueOrNull(Element.ELEMENT_DEVICE_CATEGORY)?.asStringSafe(),
            "courseName" to getValueOrNull(Element.ELEMENT_COURSE_NAME)?.asStringSafe(),
        )
    }

    private fun DataPoint.getValueOrNull(element: Element): Value? {
        return runCatching {
            getValue(element)
        }.getOrNull()?.takeIf { value -> value.isSet }
    }

    private fun Value.asIntSafe(): Int? = runCatching { asInt() }.getOrNull()

    private fun Value.asStringSafe(): String? = runCatching { asString() }.getOrNull()
}
