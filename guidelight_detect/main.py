import cv2
from ultralytics import YOLO
import os
import time
import requests

from dotenv import load_dotenv

load_dotenv("../.env")


# =========================================================
# YOLO
# =========================================================

model = YOLO("yolov8n.pt")
class_names = model.names


# =========================================================
# Dangerous Objects
# =========================================================

dangerous_objects = {
    
    "car",
    "motorcycle",
    "bus",
    "truck",
    "bicycle",
    "chair",
    "couch",
    "bench",
    "bed",
    "refrigerator",
    "mirror",
    "bottle",
    "cup",
    "dog",
    "cat",
    "stop sign",
    "traffic light",
}


# =========================================================
# Detection Settings
# =========================================================

DANGER_DISTANCE = 1.5

MIN_CONFIDENCE = 0.65

ALERT_COOLDOWN = 5

# Number of consecutive frames required
# before we consider an object a real danger.
REQUIRED_FRAMES = 3

last_alert_time = 0

danger_frames = {}


# =========================================================
# Django API
# =========================================================

API_BASE_URL = "http://127.0.0.1:8000"

DEVICE_API_KEY = os.getenv("GUIDELIGHT_DEVICE_API_KEY")

if not DEVICE_API_KEY:
    raise RuntimeError(
        "GUIDELIGHT_DEVICE_API_KEY is not set"
    )

# =========================================================
# Approximate Real Object Widths
# =========================================================
#
# These are approximate physical widths in meters.
#
# IMPORTANT:
# This is still an estimation, not a true depth sensor.
#

KNOWN_WIDTHS = {
    "person": 0.45,
    "car": 1.80,
    "motorcycle": 0.80,
    "bus": 2.50,
    "truck": 2.20,
    "bicycle": 0.60,
    "chair": 0.45,
    "couch": 1.80,
    "bench": 1.20,
    "bed": 1.60,
    "refrigerator": 0.70,
    "mirror": 0.60,
    "bottle": 0.07,
    "cup": 0.08,
    "dog": 0.30,
    "cat": 0.20,
    "stop sign": 0.75,
    "traffic light": 0.30,
}


# =========================================================
# Camera Calibration
# =========================================================
#
# This value must eventually be calibrated for your camera.
#
# We start with a reasonable prototype value.
#

FOCAL_LENGTH = 500


# =========================================================
# Distance Estimation
# =========================================================

def estimate_distance(box_width, object_name):

    if box_width <= 0:
        return None

    known_width = KNOWN_WIDTHS.get(object_name)

    if known_width is None:
        return None

    distance = (
        known_width * FOCAL_LENGTH
    ) / box_width

    return distance


# =========================================================
# Send Alert To Django
# =========================================================

def send_alert_to_api(
    message,
    distance,
    object_type
):

    global last_alert_time

    now = time.time()

    # -----------------------------------------------------
    # Cooldown
    # -----------------------------------------------------

    if now - last_alert_time < ALERT_COOLDOWN:
        return

    print()
    print("=================================")
    print("🚨 DANGER CONFIRMED")
    print("=================================")
    print(f"Object: {object_type}")
    print(f"Distance: {distance:.2f} m")
    print(f"Message: {message}")

    data = {
        "alert_type": "danger",
        "object_name": str(object_type),
        "distance": float(
            round(
                float(distance),
                2
            )
        ),
        "message": str(message),
    }

    headers = {
        "X-Device-Key": DEVICE_API_KEY,
        "Content-Type": "application/json",
    }

    try:

        response = requests.post(
            API_BASE_URL
            + "/api/device-alert/",

            json=data,

            headers=headers,

            timeout=5,
        )

        print(
            "Backend status:",
            response.status_code
        )

        print(
            "Backend response:",
            response.text
        )

        # -------------------------------------------------
        # SUCCESS
        # -------------------------------------------------

        if response.status_code == 201:

            print(
                "✅ Alert sent successfully"
            )

            # ---------------------------------------------
            # Play alarm
            # ---------------------------------------------

            sound_file = (
                "mixkit-classic-alarm-995.wav"
            )

            if os.path.exists(sound_file):

                os.system(
                    f"afplay '{sound_file}' &"
                )

            last_alert_time = time.time()

        # -------------------------------------------------
        # AUTH ERROR
        # -------------------------------------------------

        elif response.status_code == 401:

            print(
                "❌ Device authentication failed"
            )

            print(
                "❌ Check DEVICE_API_KEY"
            )

        # -------------------------------------------------
        # OTHER ERROR
        # -------------------------------------------------

        else:

            print(
                "❌ Failed to send alert"
            )

    except requests.exceptions.Timeout:

        print(
            "❌ Request timed out"
        )

    except requests.exceptions.ConnectionError:

        print(
            "❌ Could not connect to Django backend"
        )

    except Exception as e:

        print(
            "❌ Error sending alert:",
            e
        )


# =========================================================
# Process Frame
# =========================================================

def process_frame(frame):

    # -----------------------------------------------------
    # Resize
    # -----------------------------------------------------

    frame = cv2.resize(
        frame,
        (320, 240)
    )

    # -----------------------------------------------------
    # YOLO
    # -----------------------------------------------------

    results = model(
        frame,
        verbose=False,
        conf=MIN_CONFIDENCE
    )

    best_danger = None

    detected_objects = set()

    # =====================================================
    # PROCESS DETECTIONS
    # =====================================================

    for result in results:

        boxes = (
            result.boxes.xyxy
            .cpu()
            .numpy()
        )

        classes = (
            result.boxes.cls
            .cpu()
            .numpy()
        )

        confidences = (
            result.boxes.conf
            .cpu()
            .numpy()
        )

        # -------------------------------------------------
        # Every detected object
        # -------------------------------------------------

        for box, cls, conf in zip(
            boxes,
            classes,
            confidences
        ):

            name = class_names[
                int(cls)
            ].lower()

            # -------------------------------------------------
            # Ignore non-dangerous objects
            # -------------------------------------------------

            if name not in dangerous_objects:
                continue

            # -------------------------------------------------
            # Confidence
            # -------------------------------------------------

            if conf < MIN_CONFIDENCE:
                continue

            # -------------------------------------------------
            # Bounding box
            # -------------------------------------------------

            x1, y1, x2, y2 = box

            box_width = x2 - x1

            box_height = y2 - y1

            # -------------------------------------------------
            # Distance
            # -------------------------------------------------

            distance = estimate_distance(
                box_width,
                name
            )

            if distance is None:
                continue

            detected_objects.add(name)

            print(
                f"Detected: {name} | "
                f"conf={conf:.2f} | "
                f"width={box_width:.1f}px | "
                f"height={box_height:.1f}px | "
                f"distance={distance:.2f}m"
            )

            # =================================================
            # CHECK DANGER DISTANCE
            # =================================================

            if distance < DANGER_DISTANCE:

                # ---------------------------------------------
                # Increase consecutive frame count
                # ---------------------------------------------

                danger_frames[name] = (
                    danger_frames.get(name, 0)
                    + 1
                )

                print(
                    f"⚠️ {name} danger frame "
                    f"{danger_frames[name]}/"
                    f"{REQUIRED_FRAMES}"
                )

                # ---------------------------------------------
                # Keep closest danger
                # ---------------------------------------------

                if (
                    best_danger is None
                    or distance < best_danger[0]
                ):

                    best_danger = (
                        distance,
                        name,
                        conf
                    )

            else:

                # Object is outside danger zone
                danger_frames[name] = 0

    # =====================================================
    # RESET OBJECTS THAT DISAPPEARED
    # =====================================================

    for object_name in list(
        danger_frames.keys()
    ):

        if object_name not in detected_objects:

            danger_frames[object_name] = 0

    # =====================================================
    # CONFIRM DANGER
    # =====================================================

    if best_danger is not None:

        distance, name, conf = (
            best_danger
        )

        # -------------------------------------------------
        # Only alert after several consecutive frames
        # -------------------------------------------------

        if (
            danger_frames.get(name, 0)
            >= REQUIRED_FRAMES
        ):

            message = (
                f"There is {name} "
                f"at approximately "
                f"{distance:.2f} meters, "
                f"danger to the patient"
            )

            send_alert_to_api(
                message,
                distance,
                name
            )

    return results


# =========================================================
# CAMERA
# =========================================================

cap = cv2.VideoCapture(
    0,
    cv2.CAP_AVFOUNDATION
)


if not cap.isOpened():

    print(
        "❌ Error: Could not open camera."
    )

    exit()


print()
print(
    "================================="
)

print(
    "Guidelight Detection started."
)

print(
    "Danger distance:",
    DANGER_DISTANCE,
    "meters"
)

print(
    "Minimum confidence:",
    MIN_CONFIDENCE
)

print(
    "Required frames:",
    REQUIRED_FRAMES
)

print(
    "Press q to quit."
)

print(
    "================================="
)

print()


# =========================================================
# MAIN LOOP
# =========================================================

while True:

    ret, frame = cap.read()

    if not ret:

        print(
            "❌ Error: Could not read frame."
        )

        break

    # -----------------------------------------------------
    # Process frame
    # -----------------------------------------------------

    results = process_frame(
        frame
    )

    # -----------------------------------------------------
    # Draw detections
    # -----------------------------------------------------

    annotated = results[0].plot()

    cv2.imshow(
        "Guidelight",
        annotated
    )

    # -----------------------------------------------------
    # Quit
    # -----------------------------------------------------

    if (
        cv2.waitKey(1) & 0xFF
        == ord("q")
    ):

        break


# =========================================================
# CLEANUP
# =========================================================

cap.release()

cv2.destroyAllWindows()

print(
    "Guidelight Detection stopped."
)