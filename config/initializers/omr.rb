Rails.application.config.x.omr = {
  max_file_size: 20.megabytes,
  allowed_extensions: %w[.jpg .jpeg .png .pdf],
  temp_dir: Rails.root.join('tmp', 'omr_processing'),
  min_image_quality: 300,  
  min_width: 400,         
  min_height: 600,       
  min_contrast: 15,       
  audiveris_path: ENV['AUDIVERIS_PATH'] || '/usr/local/bin/audiveris',
  tessdata_prefix: ENV['TESSDATA_PREFIX'] || '/usr/local/share/tessdata'
}