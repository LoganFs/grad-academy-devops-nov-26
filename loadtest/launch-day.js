import http from 'k6/http';
import { check, sleep } from 'k6';

// Midnight Release stress test. Point it at the Terraform output:
//   k6 run -e TARGET="$(terraform -chdir=../terraform output -raw social_hub_url)" launch-day.js
//
// Mission 2: against the single vanilla VM this produces timeouts / 504s.
// Mission 4: against the load-balanced pool the error rate should drop to ~0%.

const TARGET = __ENV.TARGET || 'http://localhost';

export const options = {
  // ~2 minute spike: ramp thousands of "players", hold, then drop.
  stages: [
    { duration: '30s', target: 200 },
    { duration: '60s', target: 1000 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    // The Mission 4 goal: fast and error-free.
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1000'],
  },
};

export default function () {
  // Expensive auth call — this is what melts the single VM.
  const authRes = http.post(
    `${TARGET}/api/v1/auth`,
    JSON.stringify({ username: `player_${__VU}_${__ITER}`, password: 'launch-day' }),
    { headers: { 'Content-Type': 'application/json' }, tags: { name: 'auth' } }
  );
  check(authRes, { 'auth 200': (r) => r.status === 200 });

  // Cheaper read of the player profile.
  const profileRes = http.get(`${TARGET}/api/v1/profile?id=${__VU}`, {
    tags: { name: 'profile' },
  });
  check(profileRes, { 'profile 200': (r) => r.status === 200 });

  sleep(1);
}
