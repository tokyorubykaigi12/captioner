import os
import azure.cognitiveservices.speech as speechsdk


def recognize_from_microphone():
    to_language = "en"
    from_language = "ja-JP"
    # use trk12-v2 model.
    custom_model_id = "a53d9c7c-daf1-4ff8-8297-65ec394ce0cd"
    # You can get deviceUID list by running the inputdevicelist.m .
    deviceUID = "BlackHole2ch_UID"

    # This example requires environment variables named "SPEECH_KEY" and "SPEECH_REGION"
    speech_translation_config = speechsdk.translation.SpeechTranslationConfig(
        subscription=os.environ.get("SPEECH_KEY"),
        region=os.environ.get("SPEECH_REGION"),
    )

    speech_translation_config.endpoint_id = custom_model_id
    speech_translation_config.add_target_language(to_language)
    speech_translation_config.speech_recognition_language = from_language

    speech_translation_config.set_property(
        speechsdk.PropertyId.Speech_SegmentationStrategy, "Continuous"
    )

    audio_config = speechsdk.audio.AudioConfig(device_name=deviceUID)

    translation_recognizer = speechsdk.translation.TranslationRecognizer(
        translation_config=speech_translation_config, audio_config=audio_config
    )

    def recognized(evt):
        print(evt)
        if evt.result.reason == speechsdk.ResultReason.TranslatedSpeech:
            print("Recognized: {}".format(evt.result.text))
            print(
                """Translated into '{}': {}""".format(
                    to_language, evt.result.translations[to_language]
                )
            )
        elif evt.result.reason == speechsdk.ResultReason.NoMatch:
            print(
                "No speech could be recognized: {}".format(evt.result.no_match_details)
            )
        elif evt.result.reason == speechsdk.ResultReason.Canceled:
            cancellation_details = evt.result.cancellation_details
            print("Speech Recognition canceled: {}".format(cancellation_details.reason))
            if cancellation_details.reason == speechsdk.CancellationReason.Error:
                print("Error details: {}".format(cancellation_details.error_details))
                print("Did you set the speech resource key and region values?")

    translation_recognizer.recognized.connect(recognized)

    print("Speak into your microphone.")
    translation_recognizer.start_continuous_recognition()

    try:
        while True:
            pass
    except KeyboardInterrupt:
        translation_recognizer.stop_continuous_recognition()


recognize_from_microphone()
