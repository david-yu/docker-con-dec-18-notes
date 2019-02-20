# UCP SAML authentication

Shows that UCP can use SAML authentication for easier management.

Create a dev Okta app following https://developer.okta.com/standards/SAML/setting_up_a_saml_application_in_okta, and note its IdP metadata URL, e.g. https://dev-961615.oktapreview.com/app/exkhgbqjd4gB7HuCd0h7/sso/saml/metadata.

Log into UDP as an admin user, navigate to `Admin Settings > AuthZ & AuthN > SAML`; enable it, and copy-paste the URL abve.

Open an incognito window in your favorite browser, and log in to your UDP cluster through Okta.
