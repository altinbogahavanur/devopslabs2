import React, { useState } from 'react'

function App() {
  const [count, setCount] = useState(0)

  return (
    <div style={{
      fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
      backgroundColor: '#0d1117',
      color: '#c9d1d9',
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'center',
      alignItems: 'center'
    }}>
      <div style={{
        backgroundColor: '#161b22',
        border: '1px solid #30363d',
        borderRadius: '12px',
        padding: '40px',
        maxWidth: '500px',
        textAlign: 'center'
      }}>
        <h1 style={{ color: '#58a6ff' }}>⚛️ React SPA + Nginx</h1>
        <p style={{ color: '#8b949e' }}>
          Multi-Stage Build ile derlendi. Node.js ve npm çöp paketleri olmadan saf Nginx ile 25 MB olarak sunuluyor!
        </p>
        <button
          onClick={() => setCount(c => c + 1)}
          style={{
            backgroundColor: '#238636',
            color: 'white',
            border: 'none',
            padding: '10px 20px',
            borderRadius: '6px',
            cursor: 'pointer',
            fontSize: '16px',
            fontWeight: 'bold',
            marginTop: '15px'
          }}>
          Sayac: {count}
        </button>
      </div>
    </div>
  )
}

export default App
