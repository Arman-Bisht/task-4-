const express = require('express');
const router = express.Router();

// Mock user database (in production, use a real database)
const users = [
  { id: 1, username: 'admin', password: 'admin123', role: 'admin' },
  { id: 2, username: 'user', password: 'user123', role: 'user' }
];

// Mock JWT token generation (in production, use proper JWT library)
const generateToken = (user) => {
  return Buffer.from(JSON.stringify({ 
    id: user.id, 
    username: user.username, 
    role: user.role,
    exp: Date.now() + 3600000 // 1 hour
  })).toString('base64');
};

// Login endpoint
router.post('/login', (req, res) => {
  const { username, password } = req.body;
  
  if (!username || !password) {
    return res.status(400).json({
      error: 'Username and password are required'
    });
  }
  
  const user = users.find(u => u.username === username && u.password === password);
  
  if (!user) {
    return res.status(401).json({
      error: 'Invalid credentials'
    });
  }
  
  const token = generateToken(user);
  
  res.json({
    message: 'Login successful',
    token,
    user: {
      id: user.id,
      username: user.username,
      role: user.role
    }
  });
});

// Token validation middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }
  
  try {
    const decoded = JSON.parse(Buffer.from(token, 'base64').toString());
    
    if (decoded.exp < Date.now()) {
      return res.status(401).json({ error: 'Token expired' });
    }
    
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid token' });
  }
};

// Protected route example
router.get('/profile', authenticateToken, (req, res) => {
  res.json({
    message: 'Profile data',
    user: req.user
  });
});

// Admin-only route example
router.get('/admin', authenticateToken, (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  
  res.json({
    message: 'Admin dashboard data',
    users: users.map(u => ({ id: u.id, username: u.username, role: u.role }))
  });
});

// Logout endpoint
router.post('/logout', authenticateToken, (req, res) => {
  // In a real application, you would invalidate the token
  res.json({ message: 'Logout successful' });
});

module.exports = { router, authenticateToken };