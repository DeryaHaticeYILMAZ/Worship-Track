class PrayerTimesResponse {
  final int code;
  final String status;
  final PrayerData data;

  PrayerTimesResponse({
    required this.code,
    required this.status,
    required this.data,
  });

  factory PrayerTimesResponse.fromJson(Map<String, dynamic> json) {
    return PrayerTimesResponse(
      code: json['code'] as int,
      status: json['status'] as String,
      data: PrayerData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class PrayerData {
  final Timings timings;
  final Meta meta;

  PrayerData({
    required this.timings,
    required this.meta,
  });

  factory PrayerData.fromJson(Map<String, dynamic> json) {
    return PrayerData(
      timings: Timings.fromJson(json['timings'] as Map<String, dynamic>),
      meta: Meta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class Timings {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String sunset;
  final String maghrib;
  final String isha;
  final String imsak;
  final String midnight;
  final String firstthird;
  final String lastthird;

  Timings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.sunset,
    required this.maghrib,
    required this.isha,
    required this.imsak,
    required this.midnight,
    required this.firstthird,
    required this.lastthird,
  });

  factory Timings.fromJson(Map<String, dynamic> json) {
    return Timings(
      fajr: json['Fajr']?.toString() ?? '',
      sunrise: json['Sunrise']?.toString() ?? '',
      dhuhr: json['Dhuhr']?.toString() ?? '',
      asr: json['Asr']?.toString() ?? '',
      sunset: json['Sunset']?.toString() ?? '',
      maghrib: json['Maghrib']?.toString() ?? '',
      isha: json['Isha']?.toString() ?? '',
      imsak: json['Imsak']?.toString() ?? '',
      midnight: json['Midnight']?.toString() ?? '',
      firstthird: json['Firstthird']?.toString() ?? '',
      lastthird: json['Lastthird']?.toString() ?? '',
    );
  }
}

class Meta {
  final double latitude;
  final double longitude;
  final String timezone;
  final Method method;
  final String latitudeAdjustmentMethod;
  final String midnightMode;
  final String school;
  final Map<String, int> offset;

  Meta({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.method,
    required this.latitudeAdjustmentMethod,
    required this.midnightMode,
    required this.school,
    required this.offset,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    final rawOffset = json['offset'] as Map<String, dynamic>;
    final Map<String, int> convertedOffset = {};
    rawOffset.forEach((key, value) {
      if (value is int) {
        convertedOffset[key] = value;
      } else if (value is String) {
        convertedOffset[key] = int.tryParse(value) ?? 0;
      } else {
        convertedOffset[key] = 0;
      }
    });

    return Meta(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      timezone: json['timezone']?.toString() ?? '',
      method: Method.fromJson(json['method'] as Map<String, dynamic>),
      latitudeAdjustmentMethod: json['latitudeAdjustmentMethod']?.toString() ?? '',
      midnightMode: json['midnightMode']?.toString() ?? '',
      school: json['school']?.toString() ?? '',
      offset: convertedOffset,
    );
  }
}

class Method {
  final int id;
  final String name;
  final Map<String, dynamic> params;
  final String location;

  Method({
    required this.id,
    required this.name,
    required this.params,
    required this.location,
  });

  factory Method.fromJson(Map<String, dynamic> json) {
    return Method(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      params: json['params'] as Map<String, dynamic>? ?? {},
      location: json['location']?.toString() ?? '',
    );
  }
} 