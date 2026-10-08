"use client";

import { useState } from "react";

export default function LoanPolicy() {
  const [baseInterestRate, setBaseInterestRate] = useState("1.5");
  const [processingFee, setProcessingFee] = useState("1.0");
  const [maxLoanMultiplier, setMaxLoanMultiplier] = useState("3");
  const [minMemberTenure, setMinMemberTenure] = useState("6");
  const [penaltyRate, setPenaltyRate] = useState("2.0");
  const [serviceFee, setServiceFee] = useState("0.5");
  const [coMakerRequired, setCoMakerRequired] = useState("50000");
  const [loanProcessingTime, setLoanProcessingTime] = useState("3–5");

  const handleSavePolicy = () => {
    console.log("Saving loan policy settings");
  };

  return (
    <div className="bg-white rounded-[16px] shadow-[0_2px_10px_rgba(0,0,0,0.05)] border border-[#E5E7EB] p-6">
      <h2 className="text-[16px] font-bold text-[#111827] mb-6">Loan Policy Settings</h2>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Left Column */}
        <div className="space-y-4">
          <div>
            <label className="block text-[11px] font-medium text-[#6B7280] mb-1.5 tracking-wider uppercase">
              Base Interest Rate (%/Month)
            </label>
            <input
              type="number"
              step="0.1"
              value={baseInterestRate}
              onChange={(e) => setBaseInterestRate(e.target.value)}
              className="w-full h-[42px] pl-4 bg-white border border-[#E5E7EB] rounded-[12px] text-[16px] text-[#1F2937] focus:outline-none focus:ring-2 focus:ring-[#1F6B3A]/20 focus:border-[#1F6B3A] transition-all"
            />
          </div>

          <div>
            <label className="block text-[11px] font-medium text-[#6B7280] mb-1.5 tracking-wider uppercase">
              Processing Fee (%)
            </label>
            <input
              type="number"
              step="0.1"
              value={processingFee}
              onChange={(e) => setProcessingFee(e.target.value)}
              className="w-full h-[42px] pl-4 bg-white border border-[#E5E7EB] rounded-[12px] text-[16px] text-[#1F2937] focus:outline-none focus:ring-2 focus:ring-[#1F6B3A]/20 focus:border-[#1F6B3A] transition-all"
            />
          </div>

          <div>
            <label className="block text-[11px] font-medium text-[#6B7280] mb-1.5 tracking-wider uppercase">
              Max Loan Multiplier (× Share Capital)
            </label>
            <input
              type="number"
              value={maxLoanMultiplier}
              onChange={(e) => setMaxLoanMultiplier(e.target.value)}
              className="w-full h-[42px] pl-4 bg-white border border-[#E5E7EB] rounded-[12px] text-[16px] text-[#1F2937] focus:outline-none focus:ring-2 focus:ring-[#1F6B3A]/20 focus:border-[#1F6B3A] transition-all"
            />
          </div>

          <div>
            <label className="block text-[11px] font-medium text-[#6B7280] mb-1.5 tracking-wider uppercase">
              Min Member Tenure (Months)
            </label>
            <input
              type="number"
              value={minMemberTenure}
              onChange={(e) => setMinMemberTenure(e.target.value)}
              className="w-full h-[42px] pl-4 bg-white border border-[#E5E7EB] rounded-[12px] text-[16px] text-[#1F2937] focus:outline-none focus:ring-2 focus:ring-[#1F6B3A]/20 focus:border-[#1F6B3A] transition-all"
            />
          </div>
        </div>

        {/* Right Column */}
        <div className="space-y-4">
          <div>
            <label className="block text-[11px] font-medium text-[#6B7280] mb-1.5 tracking-wider uppercase">
              Penalty Rate (%/Month)
            </label>
            <input
              type="number"
              step="0.1"
              value={penaltyRate}
              onChange={(e) => setPenaltyRate(e.target.value)}
              className="w-full h-[42px] pl-4 bg-white border border-[#E5E7EB] rounded-[12px] text-[16px] text-[#1F2937] focus:outline-none focus:ring-2 focus:ring-[#1F6B3A]/20 focus:border-[#1F6B3A] transition-all"
            />
          </div>

          <div>
            <label className="block text-[11px] font-medium text-[#6B7280] mb-1.5 tracking-wider uppercase">
              Service Fee (%)
            </label>
            <input
              type="number"
              step="0.1"
              value={serviceFee}
              onChange={(e) => setServiceFee(e.target.value)}
              className="w-full h-[42px] pl-4 bg-white border border-[#E5E7EB] rounded-[12px] text-[16px] text-[#1F2937] focus:outline-none focus:ring-2 focus:ring-[#1F6B3A]/20 focus:border-[#1F6B3A] transition-all"
            />
          </div>

          <div>
            <label className="block text-[11px] font-medium text-[#6B7280] mb-1.5 tracking-wider uppercase">
              Co-Maker Required Above (₱)
            </label>
            <input
              type="number"
              value={coMakerRequired}
              onChange={(e) => setCoMakerRequired(e.target.value)}
              className="w-full h-[42px] pl-4 bg-white border border-[#E5E7EB] rounded-[12px] text-[16px] text-[#1F2937] focus:outline-none focus:ring-2 focus:ring-[#1F6B3A]/20 focus:border-[#1F6B3A] transition-all"
            />
          </div>

          <div>
            <label className="block text-[11px] font-medium text-[#6B7280] mb-1.5 tracking-wider uppercase">
              Loan Processing Time (Working Days)
            </label>
            <input
              type="text"
              value={loanProcessingTime}
              onChange={(e) => setLoanProcessingTime(e.target.value)}
              className="w-full h-[42px] pl-4 bg-white border border-[#E5E7EB] rounded-[12px] text-[16px] text-[#1F2937] focus:outline-none focus:ring-2 focus:ring-[#1F6B3A]/20 focus:border-[#1F6B3A] transition-all"
            />
          </div>
        </div>
      </div>

      <button
        onClick={handleSavePolicy}
        className="mt-6 px-6 h-[42px] bg-[#1F6B3A] rounded-[12px] text-[14px] font-semibold text-white hover:bg-[#14532D] transition-colors"
      >
        Save Policy
      </button>
    </div>
  );
}
