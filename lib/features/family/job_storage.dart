import 'job_model.dart';

// 🔴 clear any legacy String-based data
List<Job> jobs = [

  Job(
    title: "Nurse Needed",
    description: "Looking after an elderly patient at home.",
    category: "Nurse",
    hours: "Full-time • Day",
    salary: "€1200 - €1500",
    requiresCertification: true,
    isUrgent: true,
    createdBy: "family_1",
  ),

  Job(
    title: "Caregiver Required",
    description: "Help with daily activities and support.",
    category: "Caregiver",
    hours: "Part-time • Flexible",
    salary: "€500 - €700",
    requiresCertification: false,
    isUrgent: false,
    createdBy: "family_1",
  ),

  Job(
    title: "Physiotherapist",
    description: "Rehabilitation sessions at home.",
    category: "Physiotherapist",
    hours: "Full-time • Day",
    salary: "€1000 - €1300",
    requiresCertification: true,
    isUrgent: false,
    createdBy: "family_1",
  ),

  Job(
    title: "Night Nurse",
    description: "Overnight monitoring and care.",
    category: "Nurse",
    hours: "Full-time • Night",
    salary: "€1500 - €1800",
    requiresCertification: true,
    isUrgent: true,
    createdBy: "family_1",
  ),

  Job(
    title: "Doctor Visit",
    description: "Weekly home checkups.",
    category: "Doctor",
    hours: "Part-time • Flexible",
    salary: "€800 - €1000",
    requiresCertification: true,
    isUrgent: false,
    createdBy: "family_1",
  ),
];

String currentUserId = "guest_1"; 
// switch to "family_1" to test family view