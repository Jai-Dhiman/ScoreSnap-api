Rails.application.config.x.omr = {
  max_file_size: 10.megabytes,
  allowed_extensions: %w[.jpg .jpeg .png .pdf],
  temp_dir: Rails.root.join('tmp', 'omr_processing')
}