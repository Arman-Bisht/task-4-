const express = require('express');
const router = express.Router();

// Simple metrics collection
let metrics = {
  requests: 0,
  errors: 0,
  uptime: Date.now()
};

// Middleware to track requests
router.use((req, res, next) => {
  metrics.requests++;
  next();
});

// Get application metrics
router.get('/', (req, res) => {
  const uptimeSeconds = Math.floor((Date.now() - metrics.uptime) / 1000);
  
  res.json({
    requests_total: metrics.requests,
    errors_total: metrics.errors,
    uptime_seconds: uptimeSeconds,
    memory_usage: process.memoryUsage(),
    cpu_usage: process.cpuUsage(),
    timestamp: new Date().toISOString()
  });
});

// Reset metrics (for testing)
router.post('/reset', (req, res) => {
  metrics = {
    requests: 0,
    errors: 0,
    uptime: Date.now()
  };
  
  res.json({ message: 'Metrics reset successfully' });
});

module.exports = { router, metrics };