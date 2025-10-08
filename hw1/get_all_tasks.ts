export const endpoint = "http://192.168.255.69";
export const stuid = "529";

export async function getAllTasks() {
    const res = await fetch(`${endpoint}/tasks/stu/${stuid}`);

    const result = await res.json();

    // console.log(result);
    return result.tasks;
}


getAllTasks();