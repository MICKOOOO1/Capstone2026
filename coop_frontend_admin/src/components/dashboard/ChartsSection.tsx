import BarChartCard from "@/components/dashboard/BarChartCard";
import DonutChartCard from "@/components/dashboard/DonutChartCard";

export default function ChartsSection() {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-[17fr_8fr] gap-3 mb-3">
      <BarChartCard />
      <DonutChartCard />
    </div>
  );
}
