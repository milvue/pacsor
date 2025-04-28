HL7_MESSAGE: str = (
        "MSH|^~\\&|{hl7_defaults[SEN_APP]}|{hl7_defaults[SEN_FAC]}"
        "|{hl7_defaults[REC_APP]}|{hl7_defaults[REC_FAC]}"
        "|{hl7_defaults[MessageTimestamp]}||ORU^R01|"
        "{hl7_defaults[MessageID]}|{hl7_defaults[PROC_ID]}|2.5.1|||AL|NE|"
        "|UNICODE UTF-8|{hl7_defaults[HL7_LANG]}||\r"
        "SEG_PID"
        "SEG_PV1"
        "SEG_ORC"
        "OBR|1||{study_metadata[AccessionNumber]}|^Milvue findings|||"
        "{hl7_defaults[MessageTimestamp]}||||||||||||||||||F\r"
        "SEG_ZDS"
        "SEG_OBX1"
        "OBX||ST|milvue^SmartUrgences^LN||{study_metadata[Inference]}||||||F\r"
    )
SEG_OBX: str = "OBX||{obx_2}|{section}^LN||Text^^Base64^{content}||||||F\r"
SEG_OBX_HTML: str = "OBX||ED|CRHTML^^MOTEURIA||^text^^Base64^{content}||||||F\r"
SEG_PID: str = (
        "PID|||{study_metadata[PatientID]}^^^{study_metadata[IssuerOfPatientID]}^"
        "PI||{study_metadata[PatientName]}||{study_metadata[PatientBirthDate]}|"
        "{study_metadata[PatientSex]}|\r"
    )
SEG_PV1: str = "PV1||||||||||||||||||||||||||||||||||||||||||\r"
SEG_ORC: str = "ORC|NW||||||^^^||{hl7_defaults[MessageTimestamp]}\r"
SEG_ZDS: str = "ZDS|{study_metadata[StudyInstanceUID]}^milvue^Application^DICOM|\r"
SEG_OBX1: str = (
        "OBX||HD|^STUDYINSTANCEUID^||{study_metadata[StudyInstanceUID]}||||||X\r"
    )
DEFAULT_METADATA_DICT: dict = {
        "PatientID": "",
        "IssuerOfPatientID": "",
        "PatientName": "",
        "PatientBirthDate": "",
        "PatientSex": "",
        "Modality": "",
        "BodyPartExamined": "",
        "AccessionNumber": "",
        "StudyInstanceUID": "",
        "SeriesDescription": "",
        "SeriesInstanceUID": "",
        "SOPInstanceUID": "",
        "SOPClassUID": "",
        "MessageTimestamp": "",
        "MessageID": "",
        "Inference": "",
    }
MAN_METADATA_DICT: dict = {
        "PatientID": "P12345",
        "PatientBirthDate": "19700101",
        "PatientSex": "M",
        "AccessionNumber": "A12345",
        "IssuerOfPatientID": "",
    }
DEFAULT_REPORT_MAPPING: dict = {
        "title": "",
        "indication": "",
        "technique": "",
        "results": "",
        "conclusion": "",
        "type": "",
    }
DEFAULT_HL7_ESCAPE_DICT: dict = {
        "\r": "\\X0D\\",
        "\n": "\\X0A\\",
        "\t": "\\X09\\",
    }
