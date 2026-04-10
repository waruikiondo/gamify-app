import os
import fitz  # PyMuPDF
import json
from google import genai
from google.genai import types
from supabase import create_client, Client
from dotenv import load_dotenv

# 1. Load Environment Variables
load_dotenv()
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY")
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

# 2. Initialize Clients
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
# Initialize the NEW Gemini client
ai_client = genai.Client(api_key=GEMINI_API_KEY)

def extract_pdf_data(pdf_path):
    print(f"Extracting data from {pdf_path}...")
    doc = fitz.open(pdf_path)
    full_text = ""
    image_paths = []

    # Ensure a local temp folder exists for extracted images
    os.makedirs("temp_images", exist_ok=True)

    for page_num in range(len(doc)):
        page = doc.load_page(page_num)
        full_text += page.get_text()

        # Extract images from the page
        image_list = page.get_images()
        for img_index, img in enumerate(image_list):
            xref = img[0]
            base_image = doc.extract_image(xref)
            image_bytes = base_image["image"]
            image_ext = base_image["ext"]
            
            # Save image locally
            image_filename = f"temp_images/page{page_num}_img{img_index}.{image_ext}"
            with open(image_filename, "wb") as f:
                f.write(image_bytes)
            image_paths.append(image_filename)

    return full_text, image_paths

def upload_images_to_supabase(image_paths):
    print(f"Uploading {len(image_paths)} images to Supabase...")
    image_urls = []
    bucket_name = "quiz_figures"

    for path in image_paths:
        file_name = os.path.basename(path)
        with open(path, "rb") as f:
            # Upload to Supabase Storage (upsert prevents crashes if file exists)
            supabase.storage.from_(bucket_name).upload(file_name, f, file_options={"upsert": "true"})
            
        # Get the public URL
        public_url = supabase.storage.from_(bucket_name).get_public_url(file_name)
        image_urls.append(public_url)
        print(f"Uploaded: {public_url}")
        
        # Clean up local file
        os.remove(path)
        
    return image_urls

def format_with_ai(raw_text, image_urls):
    print("Sending text to AI for JSON formatting...")
    prompt = f"""
    You are a data extraction assistant. I am giving you raw text from a Part 107 Drone Exam PDF, and a list of image URLs extracted from that PDF.
    
    Convert the raw text into a JSON array of objects representing quiz questions.
    Each object MUST have this exact structure to match my Supabase database:
    - "question_text" (string)
    - "answer_options" (array of strings)
    - "correct_answer" (string - must exactly match one of the options)
    - "image_url" (string or null - If the question references a figure or chart, insert one of the provided image URLs here. Otherwise, null).
    
    Extracted Image URLs available to use: {image_urls}
    
    Raw PDF Text:
    {raw_text}
    """
    
    # Using the new SDK syntax
    response = ai_client.models.generate_content(
        model='gemini-2.5-flash',
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
        )
    )
    return json.loads(response.text)

def insert_into_database(json_data):
    print(f"Inserting {len(json_data)} questions into Supabase...")
    # Insert the entire JSON array into the questions table in one go
    response = supabase.table("questions").insert(json_data).execute()
    print("Database insert complete!")

# --- Main Execution ---
if __name__ == "__main__":
    # Ensure this exactly matches the filename, including spaces!
    pdf_file = "Report - Responses.pdf" 
    
    # Run the pipeline
    try:
        text, images = extract_pdf_data(pdf_file)
        urls = upload_images_to_supabase(images)
        structured_json = format_with_ai(text, urls)
        insert_into_database(structured_json)
        print("Pipeline finished successfully!")
    except Exception as e:
        print(f"An error occurred: {e}")