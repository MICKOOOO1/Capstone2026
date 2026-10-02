import StatCard from "@/components/dashboard/StatCard";
import { Users, Wallet, TrendingUp, DollarSign } from "lucide-react";

export default function StatCardsRow2() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3 mb-3">
      <StatCard
        icon={Users}
        iconBgColor=""
        iconColor=""
        label="Active Members"
        value="1,284"
        subtitle="+8 this month"
        customBgColor="#EEF4FF"
        customIconColor="#2563EB"
      />
      <StatCard
        icon={Wallet}
        iconBgColor=""
        iconColor=""
        label="Outstanding Balance"
        value="₱4.2M"
        subtitle="Total portfolio"
        customBgColor="#F6EEFF"
        customIconColor="#9333EA"
      />
      <StatCard
        icon={TrendingUp}
        iconBgColor=""
        iconColor=""
        label="Monthly Collections"
        value="₱620K"
        subtitle="Jul 2025"
        customBgColor="#EDF8F1"
        customIconColor="#166534"
      />
      <StatCard
        icon={DollarSign}
        iconBgColor=""
        iconColor=""
        label="Monthly Disbursement"
        value="₱380K"
        subtitle="Jul 2025"
        customBgColor="#FFF6EC"
        customIconColor="#F97316"
      />
    </div>
  );
}
