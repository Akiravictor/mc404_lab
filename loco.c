#include "api_robot2.h" /* Robot control API */

void danca();

void _start(void) 
{
	unsigned int distances[16];
	int    n=0, cont=0;
	set_alarm(danca,1);
	/*não bater - corrida*/
	while(1)
	{
		distances[4] = read_sonar(4);
		distances[3] = read_sonar(3);
		set_motors_speed(40, 40);
		
		if(distances[4] <= 1200 || distances[3] <= 1200)
		{
			if(distances[3] > distances[4])
			{
				set_motor_speed(1,0);
				set_motor_speed(0,25);
			}
			else
			{
				if(distances[4] > distances[3])
				{
					set_motor_speed(0,0);
					set_motor_speed(1,25);
				}
				else
				{                                     /*são iguais*/
					distances[7] = read_sonar(7);        
					distances[0] = read_sonar(0);
					if(distances[0] > distances[7])		/*verifica lado mais espaçoso*/
					{
						set_motor_speed(1,0);
						set_motor_speed(0,25);
					}
					else
					{
						set_motor_speed(0,0);
						set_motor_speed(1,25);  
					}
				} 
			}
		}
	}
}

void danca()
{
	unsigned int distances[16];
	int    n=0, cont=0;
	/*dance*/
	while(1)
	{
		set_motors_speed(20, 20);
		distances[0] = read_sonar(0);
		distances[7] = read_sonar(7);

		cont +=1;
		if(cont >= 2)
		{
			cont=0;
			if(distances[7] > 1200 && n)
			{
				set_motor_speed(0,0);
				set_motor_speed(1,40);
				n=0;
			}
			else
			{
				if(distances[0] > 1200 && n==0)
				{
					n=1;
					set_motor_speed(1,0);
					set_motor_speed(0,30);
				}
			}
		}
	}
}
