import Foundation

/// Angle calculations shared by metrics calculation and (later) the live
/// overlay annotations. All angles are returned in degrees.
///
/// Coordinate conventions (MediaPipe normalized image space): x/y are in
/// [0, 1] with the origin at the top-left and y increasing downward; z is
/// relative depth from the hip center, roughly the same scale as x, with
/// smaller (more negative) values closer to the camera.
public enum AngleMath {
    public static func degrees(_ radians: Double) -> Double {
        radians * 180 / .pi
    }

    /// Angle of the line between two landmarks within the horizontal
    /// (x, z) plane — i.e. a top-down view of the body. Used as a proxy
    /// for shoulder/hip rotation about the vertical axis, since a single
    /// 2D camera can't observe true transverse-plane rotation directly
    /// but MediaPipe's estimated z depth makes this a workable stand-in.
    public static func horizontalPlaneAngle(from a: PoseLandmark, to b: PoseLandmark) -> Double {
        degrees(atan2(b.z - a.z, b.x - a.x))
    }

    /// Angle of the line between two landmarks from vertical, in the
    /// camera's image plane (x, y). Used for spine angle / forward tilt.
    public static func verticalTiltAngle(from bottom: PoseLandmark, to top: PoseLandmark) -> Double {
        let dx = top.x - bottom.x
        let dy = bottom.y - top.y // positive when top is above bottom
        return degrees(atan2(dx, dy))
    }

    /// Shortest signed difference between two angles in degrees, normalized to [-180, 180].
    public static func angleDifference(_ a: Double, _ b: Double) -> Double {
        var diff = (a - b).truncatingRemainder(dividingBy: 360)
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        return diff
    }
}

public extension PoseFrame {
    /// Rotation of the shoulder line about the vertical axis, in degrees.
    var shoulderLineAngle: Double? {
        guard let left = self[.leftShoulder], let right = self[.rightShoulder] else { return nil }
        return AngleMath.horizontalPlaneAngle(from: left, to: right)
    }

    /// Rotation of the hip line about the vertical axis, in degrees.
    var hipLineAngle: Double? {
        guard let left = self[.leftHip], let right = self[.rightHip] else { return nil }
        return AngleMath.horizontalPlaneAngle(from: left, to: right)
    }

    /// Spine angle from vertical, in degrees, using the mid-hip to mid-shoulder line.
    var spineAngle: Double? {
        guard let hipMid = midpoint(.leftHip, .rightHip),
              let shoulderMid = midpoint(.leftShoulder, .rightShoulder) else { return nil }
        return abs(AngleMath.verticalTiltAngle(from: hipMid, to: shoulderMid))
    }
}
