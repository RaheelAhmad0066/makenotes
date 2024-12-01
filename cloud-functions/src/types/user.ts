import { Timestamp } from "firebase-admin/firestore";
import { UsageLimit } from "./usage";
import { Reward } from "./reward";

/* .dart reference
  final String uid;
  final String email;
  final String? name;
  final String? photoUrl;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final UsageLimitModel? usage;
  */
export type User = {
  uid: string;
  email: string;
  name: string | null;
  photoUrl: string | null;
  createdAt: Timestamp | null;
  updatedAt: Date | null;
  usage: UsageLimit | null;

  rewardHistory: Reward[] | null;
}
