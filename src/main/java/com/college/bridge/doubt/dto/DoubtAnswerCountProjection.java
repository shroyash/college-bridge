package com.college.bridge.doubt.dto;

public interface DoubtAnswerCountProjection {

    Long getDoubtId();

    Long getAnswerCount();

    Long getVerifiedAnswerCount();
}