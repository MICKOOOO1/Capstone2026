"use client";

import QuickActions from "@/components/dashboard/QuickActions";
import StatCardsRow1 from "@/components/dashboard/StatCardsRow1";
import StatCardsRow2 from "@/components/dashboard/StatCardsRow2";
import ChartsSection from "@/components/dashboard/ChartsSection";
import BottomSection from "@/components/dashboard/BottomSection";

export default function DashboardPage() {
  return (
    <>
      <QuickActions className="mb-4" />
      <StatCardsRow1 />
      <StatCardsRow2 />
      <ChartsSection />
      <BottomSection />
    </>
  );
}
