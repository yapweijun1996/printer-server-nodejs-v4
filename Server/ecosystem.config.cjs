module.exports = {
  apps: [
    {
      name: 'print-server',
      // The script path must be relative to the project root, where pm2 is run.
      script: './Server/index.js',
      // exec_mode: 'fork' is crucial for stability in simple servers.
      // It prevents PM2 from using the complex 'cluster' mode, which can hide errors.
      exec_mode: 'fork',
      // We no longer set 'cwd'. PM2's working directory will be the project root.
      // This ensures that 'node_modules' is always found correctly.
      watch: false,
      // --- Log Management ---
      // Log paths are now relative to the project root.
      output: './logs/out.log',
      error: './logs/error.log',
      // Merge logs from all instances of the app
      merge_logs: true,
      // Add timestamps to the logs
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
      env: {
        NODE_ENV: 'development',
      },
      env_production: {
        NODE_ENV: 'production',
      },
    },
  ],
};