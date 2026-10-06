extends MachineContainer
class_name MECraftingTerminalContainer

## Orders live in the placed terminal, so normal world saves persist their
## reservations, progress and the processing batch currently inside a machine.
const MAX_JOBS := 16
var jobs: Array[Dictionary] = []
var next_job_id := 1


func enqueue(plan: Dictionary) -> int:
	if not bool(plan.get("ready", false)) or jobs.size() >= MAX_JOBS:
		return -1
	var job := plan.duplicate(true)
	job["id"] = next_job_id
	next_job_id += 1
	job["status"] = "queued"
	job["step"] = 0
	job["completed"] = 0
	job["timer"] = 0.0
	job["in_flight"] = {}
	job["running"] = []
	jobs.append(job)
	return int(job["id"])


func cancel(job_id: int) -> void:
	for job: Dictionary in jobs:
		if int(job["id"]) == job_id:
			job["status"] = "cancelled"
			job["reserved"] = {}
			job["reserved_fluids"] = {}
			job["in_flight"] = {}
			job["running"] = []


func dismiss(job_id: int) -> void:
	for index: int in range(jobs.size() - 1, -1, -1):
		if int(jobs[index]["id"]) == job_id and not is_active(jobs[index]):
			jobs.remove_at(index)


static func is_active(job: Dictionary) -> bool:
	return str(job.get("status", "")) not in ["complete", "cancelled"]


func to_save_data() -> Dictionary:
	var data := super.to_save_data()
	data["craft_jobs"] = jobs.duplicate(true)
	data["next_job_id"] = next_job_id
	return data


func from_save_data(data: Dictionary) -> void:
	super.from_save_data(data)
	jobs.clear()
	next_job_id = maxi(int(data.get("next_job_id", 1)), 1)
	var saved: Variant = data.get("craft_jobs", [])
	if saved is Array:
		for value: Variant in saved:
			if value is Dictionary and value.get("steps") is Array and value.get("reserved") is Dictionary:
				if jobs.size() >= MAX_JOBS:
					break
				jobs.append(value.duplicate(true))
				next_job_id = maxi(next_job_id, int(value.get("id", 0)) + 1)
