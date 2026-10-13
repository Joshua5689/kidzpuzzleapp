# Play Console answer sheet: Doodle Bee - Puzzle and Play

Answers for every form Google asks for, matched to version 1.0.0.

- **Checked in the build (13 Oct 2026):** no permissions, no Advertising ID, no Google
  Play Services, no ads or analytics code, no internet use, no purchases. Player
  profiles stay on the device.
- **Before you submit:** these are declarations you make to Google, so read each one
  and make sure it's still true.
- **Why each answer:** the reason is in *italics*. If the app changes (ads, internet,
  sign-in, purchases), these answers must change too.

---

## 1. Create the app
Play Console → **Create app**

| Field | Answer |
|---|---|
| App name | `Doodle Bee - Puzzle and Play` |
| Default language | English (United Kingdom) – en-GB |
| App or game | **Game** |
| Free or paid | **Free** *(this can never be changed to paid later)* |
| Declarations | Tick both: Developer Program Policies, and US export laws |

---

## 2. App content
Play Console → **Policy and programs → App content**, one card per form.

### 2.1 Privacy policy
- URL: `https://joshua5689.github.io/kidzpuzzleapp/privacy-policy.html`

### 2.2 App access
- **All functionality in my app is available without any access restrictions**
- *There are no logins, passwords or memberships.*

### 2.3 Ads
- **No, my app does not contain ads**

### 2.4 Content rating (IARC questionnaire)
- **Email:** `tjoshuaanderson@gmail.com`
- **Category:** **Game** *(the closest fit for a puzzle game)*
- Answer **No** to every question:

| Question topic | Answer |
|---|---|
| Violence, blood, fear / scary content | No |
| Sexuality, nudity | No |
| Bad language / crude humour | No |
| Drugs, alcohol, tobacco | No |
| Gambling or simulated gambling | No |
| Users can interact or exchange content with each other (chat, sharing) | No |
| Shares the user's current location with other users | No |
| Lets users buy digital goods | No |
| Unrestricted internet access (e.g. a web browser) | No |
| Is this a web browser or search engine | No |
| Contains NFTs / blockchain | No |

- **Expected result:** Everyone / PEGI 3 / USK 0 / 3+ in most countries.

### 2.5 Target audience and content
- **Target age groups:** tick **5 and under** and **6–8**. Leave every older group unticked.
  - *These match the game: ages 2–6, with World 5 fun up to 8. Choosing only
    under-13 groups puts the app under Google's **Families Policy**, which the app
    already meets: no ads, no data collection, no third-party code.*
- **"Could your store listing unintentionally appeal to children?"** If asked, it's
  not relevant: the app is meant for children.
- **Families Policy requirements:** accept and confirm compliance.
- **Ads or third-party SDKs:** none.
- **Teacher Approved:** optional, apply later if you like.

### 2.6 News app
- **No**

### 2.7 Data safety
The key fact: Google defines "collect" as **sending data off the device**. Saving
player names and stars only on the tablet is *not* collection.

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| *(Questions about encryption in transit and deletion requests are then skipped or not applicable.)* | |

- **Expected store label:** "No data collected" and "No data shared with third parties".
- *Optional for later:* the independent security review badge is a separate paid
  programme. Leave it.

### 2.8 Government apps
- **No**

### 2.9 Financial features
- **My app doesn't provide any financial features**

### 2.10 Health
- **My app does not have any health features**

### 2.11 Advertising ID
- **No**. *The build contains no Advertising ID permission and no ad or analytics code.*

### 2.12 Anything else on the page
If anything else shows up (e.g. "Restricted permissions", "Photo and video
permissions"): **not applicable**, because the app requests no permissions.

---

## 3. Store settings
Play Console → **Grow users → Store presence → Store settings**

| Field | Answer |
|---|---|
| App category | **Educational** *(alternative: Puzzle)* |
| Tags | Pick up to 5 from Google's list, e.g. Educational, Puzzle, Brain games, Kids, Casual |
| Email | `tjoshuaanderson@gmail.com` |
| Phone / website | Optional, leave blank |
| External marketing | Your choice (lets Google promote the app outside Play) |

## 4. Main store listing
Play Console → **Store presence → Main store listing**
- **Text:** copy from `store/listing.txt` (app name, short and full description).
- **App icon:** `store/icon-512.png`
- **Feature graphic:** `store/feature-graphic-1024x500.png`
- **Screenshots:**
  - Phone: `store/screenshots/1920x1080/` (all 8, in name order)
  - 7-inch tablet: the same files as phone
  - 10-inch tablet: `store/screenshots/2560x1440/`
- **Video:** none for now, leave empty.

## 5. Pricing and countries
- Price: **Free**
- Countries: **all**, or choose specific ones
- No in-app products or subscriptions

---

## 6. Releases

### 6.1 Play App Signing (asked on your first upload)
- Choose **Use Google-generated key**, the default and recommended option.
  - *Your `doodlebee-upload.keystore` becomes the **upload key**. Google keeps the
    real signing key. If you ever lose the upload key, Google can reset it.*
- Keep the keystore file and its password backed up anyway.

### 6.2 Internal testing (do this first: instant, no review wait)
**Testing → Internal testing → Create new release**
- **Upload:** `build/android/DoodleBee.aab`
- **Release name:** `1.0.0`
- **Release notes:**
  ```
  <en-GB>
  First release of Doodle Bee: 50 puzzle games for young children, read aloud, offline, no ads.
  </en-GB>
  ```
- **Testers:** add your own Gmail and family's under the **Testers** tab. Then open
  the opt-in link on the tablet and install from the Play Store.

### 6.3 Closed testing
*Needed for personal accounts created after November 2023 before going to production.*
- **Requirement:** at least **12 testers** must stay opted in for **14 days in a row**.
- **Testing → Closed testing → Create track:**
  - upload the same AAB, or promote the internal release;
  - add testers by email list or a Google Group.
- **Good testers:** parents from school or nursery, family and friends with Android
  devices. They must accept the invite link and install from Play.
- **During the 14 days:** watch the testers' feedback. Fixes mean a new upload with a
  higher **version code**; ask me to bump it.

### 6.4 Apply for production
Google asks a short questionnaire after the closed test. Suggested answers:
- **How did you recruit testers?** Family, friends and parents of young children who
  use Android tablets.
- **How did they engage?** They played through the worlds with their children (ages 2–8).
- **What did you learn / change?** e.g. difficulty of star thresholds, read-aloud prompts.
  Fill in what really happened.
- **Is the app ready?** Yes.

After approval: **Production → Create release → promote the closed-test release**.
The first review of a children's app usually takes a few days, sometimes about a week.

---

## 7. Every future update
1. Ask Claude to bump the version (`version/code` +1, e.g. 2; `version/name` e.g. `1.0.1`)
   in `export_presets.cfg` and rebuild `DoodleBee.aab`.
2. Upload to a testing track, then promote to production.
3. If anything about data, ads or permissions changes, update sections 2.3, 2.7 and
   2.11 and the privacy policy **before** releasing.
