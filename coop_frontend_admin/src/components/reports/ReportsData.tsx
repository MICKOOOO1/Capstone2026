export interface ChartData {
  month: string;
  value: number;
}

export interface MonthlyData {
  applications: string;
  approved: string;
  released: string;
  collections: string;
}

export const chartData: ChartData[] = [
  { month: "Feb", value: 24 },
  { month: "Mar", value: 30 },
  { month: "Apr", value: 28 },
  { month: "May", value: 34 },
  { month: "Jun", value: 41 },
  { month: "Jul", value: 38 },
];

export const monthlyData: Record<string, MonthlyData> = {
  "February 2025": { applications: "24", approved: "18", released: "₱890K", collections: "₱420K" },
  "March 2025": { applications: "30", approved: "23", released: "₱1.05M", collections: "₱510K" },
  "April 2025": { applications: "28", approved: "21", released: "₱980K", collections: "₱480K" },
  "May 2025": { applications: "34", approved: "26", released: "₱1.15M", collections: "₱560K" },
  "June 2025": { applications: "41", approved: "32", released: "₱1.35M", collections: "₱680K" },
  "July 2025": { applications: "38", approved: "29", released: "₱1.24M", collections: "₱620K" },
  "August 2025": { applications: "35", approved: "27", released: "₱1.18M", collections: "₱590K" },
  "September 2025": { applications: "32", approved: "25", released: "₱1.10M", collections: "₱550K" },
  "October 2025": { applications: "29", approved: "22", released: "₱1.02M", collections: "₱510K" },
  "November 2025": { applications: "27", approved: "20", released: "₱950K", collections: "₱470K" },
  "December 2025": { applications: "25", approved: "19", released: "₱920K", collections: "₱450K" },
  "January 2025": { applications: "22", approved: "17", released: "₱850K", collections: "₱410K" },
};

export const summaryMetrics = [
  { value: "38", label: "Total Applications" },
  { value: "29", label: "Total Approved" },
  { value: "₱1.24M", label: "Total Released" },
  { value: "₱620K", label: "Total Collections" },
];
