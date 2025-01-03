import os
from moviepy.video.io.VideoFileClip import VideoFileClip
from moviepy.video.VideoClip import TextClip
from moviepy.video.compositing.CompositeVideoClip import CompositeVideoClip
import logging
import traceback

# Use the logger configured in the caller
logger = logging.getLogger(__name__)

# Function to get codecs based on file extension
def get_codecs_by_extension(extension):
    codecs = {
        ".webm": {"video_codec": "libvpx", "audio_codec": "libvorbis"},
        ".mp4": {"video_codec": "libx264", "audio_codec": "aac"},
        ".ogv": {"video_codec": "libtheora", "audio_codec": "libvorbis"},
        ".mkv": {"video_codec": "libx264", "audio_codec": "aac"},
    }
    return codecs.get(extension, {"video_codec": "libx264", "audio_codec": "aac"})

# Helper function to convert newlines to spaces
def convert_newlines_to_spaces(text):
    return text.replace("\n", "                      ")

def add_captions(params):
    """
    Add captions to a video based on parameters.

    Args:
        params (dict): Dictionary containing parameters for captioning.
            Required keys:
                - input_video_path (str): Path to the input video file.
                - download_path (str): Path to save the output video.
                - font (str): Font for captions.
                - font_size (int): Font size for captions.
                - caption_top (str): Top position percentage for captions.
                - caption_bottom (str): Bottom position percentage for captions.
                - line_width (str): Maximum line width as a percentage.
                - hor_offset (str): Horizontal offset as a percentage.
                - cap_length (int): Duration of each caption in seconds.
                - max_number (int): Maximum number of captions.
                - max_char_width (int): Maximum character width per line.
                - next_line (float): Line spacing factor for multi-line captions.
                - pause_between_para (int): Pause duration between paragraphs.
                - source_path (str): Path to the captions text file.

    Returns:
        dict: Result containing the output video path.
    """
    try:
        # Extract parameters
        input_video_path = params.get("input_video_path")
        download_path = params.get("download_path")
        font = params.get("font", "Arial-Bold")
        font_size = params.get("font_size", 48)
        caption_top = params.get("caption_top", "15%")
        caption_bottom = params.get("caption_bottom", "75%")
        line_width = params.get("line_width", "8%")
        hor_offset = params.get("hor_offset", "4%")
        cap_length = params.get("cap_length", 5)
        max_number = params.get("max_number", 60)
        max_char_width = params.get("max_char_width", 65)
        next_line = params.get("next_line", 1.7)
        pause_between_para = params.get("pause_between_para", 2)
        

	logger.debug("Debug log from the library.")
	logger.info("Info log from the library.")


        # Debugging the caller directory and default source path
        logger.debug("Starting path resolution...")
        caller_dir = os.path.dirname(os.path.abspath(__file__))
        logger.debug(f"Caller directory resolved to: {caller_dir}")

        # Determine the project base directory (two levels up from the library)
        project_base_dir = os.path.abspath(os.path.join(caller_dir, "../.."))
        logger.debug(f"Project base directory resolved to: {project_base_dir}")

        # Default source path
        default_source_path = os.path.join(project_base_dir, "data/4.source.txt")
        logger.debug(f"Default source path: {default_source_path}")

        # Use the provided source path or default
        provided_source_path = params.get("source_path")
        if provided_source_path and os.path.isfile(provided_source_path):
            source_path = os.path.abspath(provided_source_path)
            logger.debug(f"Using provided source path: {source_path}")
        else:
            logger.debug(f"Invalid or missing provided source path: {provided_source_path}, using default.")
            source_path = os.path.abspath(default_source_path)

        logger.debug(f"Final resolved source path: {source_path}")

        # Validate the resolved source path
        if not os.path.isfile(source_path):
            logger.debug(f"File does not exist at path: {source_path}")
            raise FileNotFoundError(f"Captions file not found: {source_path}")

        # Log success if file exists
        logger.debug(f"Captions file exists: {source_path}")

        # Read captions from the source file
        with open(source_path, "r") as f:
            captions = [line.strip() for line in f if line.strip()]

        if not captions:
            raise ValueError("No captions found in the source file.")

        # Generate output video path
        output_video_path = "tja"

        logger.info(f"Captions added successfully. Output saved to {output_video_path}")
        return {"output_video_path": output_video_path}
    except Exception as e:
        logger.error(f"Error adding captions: {e}")
        logger.debug(traceback.format_exc())
        raise

# Function to create a unique output path by appending a counter to the filename
def unique_output_path(path, filename):
    base, ext = os.path.splitext(filename)
    counter = 1
    unique_filename = filename
    while os.path.exists(os.path.join(path, unique_filename)):
        unique_filename = f"{base}_{counter}{ext}"
        counter += 1
    return os.path.join(path, unique_filename)

