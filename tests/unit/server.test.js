const request = require('supertest');
const app = require('../../src/api/server');

describe('DevOps API Server', () => {
  describe('GET /health', () => {
    it('should return health status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);
      
      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('version');
      expect(response.body).toHaveProperty('environment');
    });
  });

  describe('GET /api/status', () => {
    it('should return API status', async () => {
      const response = await request(app)
        .get('/api/status')
        .expect(200);
      
      expect(response.body).toHaveProperty('message');
      expect(response.body).toHaveProperty('environment');
      expect(response.body).toHaveProperty('timestamp');
    });
  });

  describe('GET /api/info', () => {
    it('should return project information', async () => {
      const response = await request(app)
        .get('/api/info')
        .expect(200);
      
      expect(response.body).toHaveProperty('project');
      expect(response.body).toHaveProperty('version');
      expect(response.body).toHaveProperty('features');
      expect(Array.isArray(response.body.features)).toBe(true);
    });
  });

  describe('GET /nonexistent', () => {
    it('should return 404 for non-existent routes', async () => {
      const response = await request(app)
        .get('/nonexistent')
        .expect(404);
      
      expect(response.body).toHaveProperty('error', 'Route not found');
      expect(response.body).toHaveProperty('path', '/nonexistent');
    });
  });
});