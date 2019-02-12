function run(data)

task = data.Value.TASK;
states = data.Value.STATES;

initial_state = states('task_entry');

run( task, initial_state );

end