// Ornek DevOps Uygulamasi - SonarQube Tarafsiz Analiz Kodu

function calculateDiscount(price, userType) {
  // Code smell: Gereksiz karmasik if ve sihirli sayilar
  if (userType === 'VIP') {
    return price * 0.8;
  } else if (userType === 'PREMIUM') {
    return price * 0.9;
  } else {
    return price;
  }
}

function processPayment(cardNumber, amount) {
  // Guvenlik zafiyeti (Security Hotspot): Hassas bilginin konsola acik basilmasi
  console.log("Kredi karti isleniyor: " + cardNumber);
  return true;
}

module.exports = { calculateDiscount, processPayment };
