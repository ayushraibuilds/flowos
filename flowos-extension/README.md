# FlowOS browser extension

The extension tracks browsing activity locally. Account sync is enabled only in a release build whose `config.js` contains the FlowOS Supabase URL and publishable key. Customers should never be asked for either value.

`config.js` intentionally ships blank in this repository. With blank values, the account controls are disabled and the extension plainly says that browsing insights remain local.
