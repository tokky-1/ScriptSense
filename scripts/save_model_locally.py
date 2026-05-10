# run from the project root: python scripts/save_trocr_locally.py
from transformers import TrOCRProcessor, VisionEncoderDecoderModel

save_path = "./model/saved_models/trocr"

processor = TrOCRProcessor.from_pretrained("microsoft/trocr-large-handwritten")
model = VisionEncoderDecoderModel.from_pretrained("microsoft/trocr-large-handwritten")

processor.save_pretrained(save_path)
model.save_pretrained(save_path)
print("Saved to", save_path)
