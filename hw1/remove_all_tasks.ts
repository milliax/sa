import { getAllTasks, endpoint, stuid } from "./get_all_tasks";

async function removeTask(taskId: string) {
    const res = await fetch(`${endpoint}/tasks/${taskId}`, {
        method: "DELETE"
    });
}


(async()=>{
    const tasks = await getAllTasks();

    for(const task of tasks){
        await removeTask(task.id);
    }

    console.log(`Removed all tasks for student ${stuid}`);
})()