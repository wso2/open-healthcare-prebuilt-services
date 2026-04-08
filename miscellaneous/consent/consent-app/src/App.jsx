import ConsentPage from './ConsentPage';

const props = window.__CONSENT_PROPS__;

export default function App() {
  if (!props) {
    return (
      <div style={{ fontFamily: 'monospace', padding: '2rem', color: '#d32f2f' }}>
        <strong>Missing consent props.</strong> This page must be served by the Ballerina consent service.
      </div>
    );
  }

  return <ConsentPage {...props} />;
}
