const db = require('../firebase/firebase');
const admin = require('firebase-admin');

async function login(req, res) {
  const { email, password } = req.body;
  
  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    
    if (!userRecord) {
      return res.status(404).json({ message: "Пользователь не найден" });
    }

    const userDoc = await db.collection('Users').doc(userRecord.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ message: "Пользователь не найден в базе данных" });
    }

    res.json({ 
      userID: userRecord.uid,
      profession: userDoc.data().Proffesion,
      message: "Вход выполнен успешно"
    });
  } catch (error) {
    res.status(500).json({ message: "Ошибка входа", error });
  }
}


async function register(req, res) {
  const { name, email, password } = req.body;

  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
    });

    await db.collection('Users').doc(userRecord.uid).set({
      Name: name,
      Proffesion: 'Неподтвержденный аккаунт',
      defaultBreak: { start: '00:00', end: '00:00' },
      mail: email,
      quota: '00:00',
      weekends: [6, 7],
    });

    res.json({ message: "Регистрация успешна", userID: userRecord.uid });
  } catch (error) {
    res.status(500).json({ message: "Ошибка регистрации", error });
  }
}

module.exports = { login, register };
