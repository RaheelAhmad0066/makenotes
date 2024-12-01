
export type UsageLimit = {
  mediaUsage: number | null;
  userId: string;
  usageLimit: number | null;
  mediaUsageLimit: number | null;
}

export type Usage = {
  userId: string;
  usageLimit: number | null;
  usage: number;
  mediaUsage: number;
  mediaUsageLimit: number | null;
}
