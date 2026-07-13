// Release configuration injected by the FlowOS extension build.
// The Supabase publishable key identifies the project; it is not a user secret.
// Leave both values blank in source builds so account sync is visibly disabled
// instead of asking customers to configure infrastructure themselves.
globalThis.FLOWOS_CONFIG = Object.freeze({
  supabaseUrl: '',
  supabasePublishableKey: '',
});
