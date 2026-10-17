// Trusted local-emulator admin only; never accepts a project/host override.
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8087'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099')throw Error('Local Auth/Firestore emulators required');
const app=initializeApp({projectId:'demo-accesstransit'},'local-review-admin');
try {
  const auth=getAuth(app),db=getFirestore(app),email='admin@local.test';
  let user;
  try{user=await auth.getUserByEmail(email);}catch(e){if(e.code!=='auth/user-not-found')throw e;user=await auth.createUser({email,password:'LocalTest-Only25!'});}
  await auth.setCustomUserClaims(user.uid,{...user.customClaims,admin:true});
  const profile=db.doc('users/'+user.uid);
  if(!(await profile.get()).exists)await profile.create({uid:user.uid,email,name:'LOCAL TEST Admin',role:'passenger',points:0,reportsSubmitted:0,verifiedCount:0,createdAt:new Date(),validationOnly:true});
  console.log('LOCAL ONLY: admin@local.test ready. Sign in again to refresh the admin claim. No existing transit or moderation data reset.');
}finally{await deleteApp(app);}
