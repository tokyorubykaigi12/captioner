import { useEffect } from 'react';

function App() {
  useEffect(() => {
    console.log('App component mounted');
  }, [])

  return (
    <div>
      Hi, Tokyo RubyKaigi 12.
    </div>
  );
}

export default App;
