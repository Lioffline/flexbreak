const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const authRoutes = require('./routes/auth');

dotenv.config();

const app = express();
app.use(express.json());
app.use(cors()); // Добавляет поддержку CORS

// Корневой маршрут
app.get('/', (req, res) => {
  res.send('Сервер работает!');
});

// Подключаем маршруты аутентификации
app.use('/auth', authRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Сервер запущен на порту ${PORT}`);
});
