/*******************************************************************************
* File Name: DAC_P_PM.c  
* Version 1.90
*
* Description:
*  This file provides the power management source code to API for the
*  VDAC8.  
*
* Note:
*  None
*
********************************************************************************
* Copyright 2008-2012, Cypress Semiconductor Corporation.  All rights reserved.
* You may use this file only in accordance with the license, terms, conditions, 
* disclaimers, and limitations in the end user license agreement accompanying 
* the software package with which this file was provided.
*******************************************************************************/

#include "DAC_P.h"

static DAC_P_backupStruct DAC_P_backup;


/*******************************************************************************
* Function Name: DAC_P_SaveConfig
********************************************************************************
* Summary:
*  Save the current user configuration
*
* Parameters:  
*  void  
*
* Return: 
*  void
*
*******************************************************************************/
void DAC_P_SaveConfig(void) 
{
    if (!((DAC_P_CR1 & DAC_P_SRC_MASK) == DAC_P_SRC_UDB))
    {
        DAC_P_backup.data_value = DAC_P_Data;
    }
}


/*******************************************************************************
* Function Name: DAC_P_RestoreConfig
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
*******************************************************************************/
void DAC_P_RestoreConfig(void) 
{
    if (!((DAC_P_CR1 & DAC_P_SRC_MASK) == DAC_P_SRC_UDB))
    {
        if((DAC_P_Strobe & DAC_P_STRB_MASK) == DAC_P_STRB_EN)
        {
            DAC_P_Strobe &= (uint8)(~DAC_P_STRB_MASK);
            DAC_P_Data = DAC_P_backup.data_value;
            DAC_P_Strobe |= DAC_P_STRB_EN;
        }
        else
        {
            DAC_P_Data = DAC_P_backup.data_value;
        }
    }
}


/*******************************************************************************
* Function Name: DAC_P_Sleep
********************************************************************************
* Summary:
*  Stop and Save the user configuration
*
* Parameters:  
*  void:  
*
* Return: 
*  void
*
* Global variables:
*  DAC_P_backup.enableState:  Is modified depending on the enable 
*  state  of the block before entering sleep mode.
*
*******************************************************************************/
void DAC_P_Sleep(void) 
{
    /* Save VDAC8's enable state */    
    if(DAC_P_ACT_PWR_EN == (DAC_P_PWRMGR & DAC_P_ACT_PWR_EN))
    {
        /* VDAC8 is enabled */
        DAC_P_backup.enableState = 1u;
    }
    else
    {
        /* VDAC8 is disabled */
        DAC_P_backup.enableState = 0u;
    }
    
    DAC_P_Stop();
    DAC_P_SaveConfig();
}


/*******************************************************************************
* Function Name: DAC_P_Wakeup
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
*  DAC_P_backup.enableState:  Is used to restore the enable state of 
*  block on wakeup from sleep mode.
*
*******************************************************************************/
void DAC_P_Wakeup(void) 
{
    DAC_P_RestoreConfig();
    
    if(DAC_P_backup.enableState == 1u)
    {
        /* Enable VDAC8's operation */
        DAC_P_Enable();

        /* Restore the data register */
        DAC_P_SetValue(DAC_P_Data);
    } /* Do nothing if VDAC8 was disabled before */    
}


/* [] END OF FILE */
