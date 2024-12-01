import { Timestamp } from "firebase-admin/firestore";
import { Reward } from "./reward";

export type PromoCode = {
    code: string;
    redeemedBy: string[];
    maxRedemptions: number | null | undefined;
    reward: Reward;
    expiresAt: Timestamp;
    createdAt: Timestamp;
}
