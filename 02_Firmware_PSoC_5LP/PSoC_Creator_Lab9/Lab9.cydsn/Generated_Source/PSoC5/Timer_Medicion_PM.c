/*******************************************************************************
* File Name: Timer_Medicion_PM.c
* Version 2.80
*
*  Description:
*     This file provides the power management source code to API for the
*     Timer.
*
*   Note:
*     None
*
*******************************************************************************
* Copyright 2008-2017, Cypress Semiconductor Corporation.  All rights reserved.
* You may use this file only in accordance with the license, terms, conditions,
* disclaimers, and limitations in the end user license agreement accompanying
* the software package with which this file was provided.
********************************************************************************/

#include "Timer_Medicion.h"

static Timer_Medicion_backupStruct Timer_Medicion_backup;


/*******************************************************************************
* Function Name: Timer_Medicion_SaveConfig
********************************************************************************
*
* Summary:
*     Save the current user configuration
*
* Parameters:
*  void
*
* Return:
*  void
*
* Global variables:
*  Timer_Medicion_backup:  Variables of this global structure are modified to
*  store the values of non retention configuration registers when Sleep() API is
*  called.
*
*******************************************************************************/
void Timer_Medicion_SaveConfig(void) 
{
    #if (!Timer_Medicion_UsingFixedFunction)
        Timer_Medicion_backup.TimerUdb = Timer_Medicion_ReadCounter();
        Timer_Medicion_backup.InterruptMaskValue = Timer_Medicion_STATUS_MASK;
        #if (Timer_Medicion_UsingHWCaptureCounter)
            Timer_Medicion_backup.TimerCaptureCounter = Timer_Medicion_ReadCaptureCount();
        #endif /* Back Up capture counter register  */

        #if(!Timer_Medicion_UDB_CONTROL_REG_REMOVED)
            Timer_Medicion_backup.TimerControlRegister = Timer_Medicion_ReadControlRegister();
        #endif /* Backup the enable state of the Timer component */
    #endif /* Backup non retention registers in UDB implementation. All fixed function registers are retention */
}


/*******************************************************************************
* Function Name: Timer_Medicion_RestoreConfig
********************************************************************************
*
* Summary:
*  Restores the current user configuration.
*
* Parameters:
*  void
*
* Return:
*  void
*
* Global variables:
*  Timer_Medicion_backup:  Variables of this global structure are used to
*  restore the values of non retention registers on wakeup from sleep mode.
*
*******************************************************************************/
void Timer_Medicion_RestoreConfig(void) 
{   
    #if (!Timer_Medicion_UsingFixedFunction)

        Timer_Medicion_WriteCounter(Timer_Medicion_backup.TimerUdb);
        Timer_Medicion_STATUS_MASK =Timer_Medicion_backup.InterruptMaskValue;
        #if (Timer_Medicion_UsingHWCaptureCounter)
            Timer_Medicion_SetCaptureCount(Timer_Medicion_backup.TimerCaptureCounter);
        #endif /* Restore Capture counter register*/

        #if(!Timer_Medicion_UDB_CONTROL_REG_REMOVED)
            Timer_Medicion_WriteControlRegister(Timer_Medicion_backup.TimerControlRegister);
        #endif /* Restore the enable state of the Timer component */
    #endif /* Restore non retention registers in the UDB implementation only */
}


/*******************************************************************************
* Function Name: Timer_Medicion_Sleep
********************************************************************************
*
* Summary:
*     Stop and Save the user configuration
*
* Parameters:
*  void
*
* Return:
*  void
*
* Global variables:
*  Timer_Medicion_backup.TimerEnableState:  Is modified depending on the
*  enable state of the block before entering sleep mode.
*
*******************************************************************************/
void Timer_Medicion_Sleep(void) 
{
    #if(!Timer_Medicion_UDB_CONTROL_REG_REMOVED)
        /* Save Counter's enable state */
        if(Timer_Medicion_CTRL_ENABLE == (Timer_Medicion_CONTROL & Timer_Medicion_CTRL_ENABLE))
        {
            /* Timer is enabled */
            Timer_Medicion_backup.TimerEnableState = 1u;
        }
        else
        {
            /* Timer is disabled */
            Timer_Medicion_backup.TimerEnableState = 0u;
        }
    #endif /* Back up enable state from the Timer control register */
    Timer_Medicion_Stop();
    Timer_Medicion_SaveConfig();
}


/*******************************************************************************
* Function Name: Timer_Medicion_Wakeup
********************************************************************************
*
* Summary:
*  Restores and enables the user configuration
*
* Parameters:
*  void
*
* Return:
*  void
*
* Global variables:
*  Timer_Medicion_backup.enableState:  Is used to restore the enable state of
*  block on wakeup from sleep mode.
*
*******************************************************************************/
void Timer_Medicion_Wakeup(void) 
{
    Timer_Medicion_RestoreConfig();
    #if(!Timer_Medicion_UDB_CONTROL_REG_REMOVED)
        if(Timer_Medicion_backup.TimerEnableState == 1u)
        {     /* Enable Timer's operation */
                Timer_Medicion_Enable();
        } /* Do nothing if Timer was disabled before */
    #endif /* Remove this code section if Control register is removed */
}


/* [] END OF FILE */
